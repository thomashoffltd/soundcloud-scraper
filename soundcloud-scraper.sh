#!/bin/bash
# A tool to recursively scrape soundcloud for tracks.
#
# Dependencies:
# parallel, getops, youtube-dl

#This function prints the help/usage information
function usage()
{
	cat << HEREDOC
	This tool is for downloading music from Soundcloud.
	
	Usage: $progname [--artist ARTIST_STR] [--recursions RECURSIONS_STR]
					 [--verbose] [--help]

	Arguments:
	-h, --help							show this help message and exit
	-a, --artist ARTIST_STR				specify artist's name
	-r, --recursions RECURSIONS_STR		specify how many recursions
	-v, --verbose						increase the verbosity of the bash script

	Example Usage:
	$prognamel --artist michael-red --recursions 2

HEREDOC
}  

#This function gathers the artist's followers
function gatherfollowers()
{
	for NUM in $(seq 0 ${recursions_str});do
        if (( $NUM == 0 )); then
			echo "${artist_str}" > artists.tmp
			
		else
			for FOLLOWER in $(cat artists.tmp); do 
				curl https://soundcloud.com/${FOLLOWER}/following 2>>/dev/null | grep -Eo "itemprop=\"url\" href=\".*\"" | sed "s/itemprop=\"url\" href=\"\///" | sed "s/\"//" >> artists.tmp
			done
			
		fi
		sort artists.tmp | uniq -c | sort -nr | sed -E "s/^.*   [0-9]{1,3} //" > sorted.list
		mv sorted.list artists.tmp
	done
}

#This function gets all the target URLS for an artist
function geturls()
{
	for ARTIST in $(cat artists.tmp);do
		mkdir -p soundcloud-scraper/$ARTIST
		cd soundcloud-scraper/$ARTIST
	        curl https://soundcloud.com/$ARTIST 2>>/dev/null| grep -Eo "itemprop=\"url\" href=\".*\"" | sed "s/itemprop=\"url\" href=\"/\"https:\/\/soundcloud\.com/" > $ARTIST-soundcloud-urls.list
       		curl https://soundcloud.com/$ARTIST/reposts 2>>/dev/null| grep -Eo "itemprop=\"url\" href=\".*\"" | sed "s/itemprop=\"url\" href=\"/\"https:\/\/soundcloud\.com/" >> $ARTIST-soundcloud-urls.list
      		curl https://soundcloud.com/$ARTIST/sets 2>>/dev/null| grep -Eo "itemprop=\"url\" href=\".*\"" | sed "s/itemprop=\"url\" href=\"/\"https:\/\/soundcloud\.com/" >> $ARTIST-soundcloud-urls.list
       		curl https://soundcloud.com/$ARTIST/albums 2>>/dev/null| grep -Eo "itemprop=\"url\" href=\".*\"" | sed "s/itemprop=\"url\" href=\"/\"https:\/\/soundcloud\.com/" >> $ARTIST-soundcloud-urls.list
        	curl https://soundcloud.com/$ARTIST/tracks 2>>/dev/null| grep -Eo "itemprop=\"url\" href=\".*\"" | sed "s/itemprop=\"url\" href=\"/\"https:\/\/soundcloud\.com/" >> $ARTIST-soundcloud-urls.list
		cd ../../
	done
}

#This function downloads all the tracks from the soundcloud-url.list file.
function downloadtracks()
{
	for ARTIST in $(cat artists.tmp);do
		echo "ARTIST=${ARTIST}"
		cd soundcloud-scraper/$ARTIST
		sed  "s/\"//g" $ARTIST-soundcloud-urls.list | parallel --jobs=8 "youtube-dl {}" 2>> /dev/null | grep -Eo "Destination:.*" | sed "s/Destination: /soundcloud\-scraper\/${ARTIST}\//"
		rm $ARTIST-soundcloud-urls.list
		cd ../../
	done
	rm artists.tmp
}



#This function prints all the variables specified.
function printverbose()
{
	cat <<-EOM
		artist=$artist_str
		recursions=$recursions_str
		verbose=$verbose
	EOM
}

# This initializes the default variables
progname=$(basename $0)
artist_str=michaelred
recursions_str=0
verbose=0

# use getopt and store the output into $OPTS
# note the use of -o for the short options, --long for the long name options
# and a : for any option that takes a parameter
OPTS=$(getopt -o "ha:r:v" --long "help,artist:,recursions:,verbose" -n "$progname" -- "$@")
if [ $? != 0 ] ; then echo "Error in command line arguments." >&2 ; usage; exit 1 ; fi
eval set -- "$OPTS"

while true; do
  # uncomment the next line to see how shift is working
  # echo "\$1:\"$1\" \$2:\"$2\""
	case "$1" in
		-h | --help ) 		usage; exit; ;;
		-a | --artist ) 	artist_str="$2"; shift 2 ;;
		-r | --recursions )	recursions_str="$2"; shift 2 ;;
		-v | --verbose )	verbose=1; shift ;;
		-- ) shift; break ;;
		* ) break ;;
	esac
done

if (( $verbose > 0 )); then
	printverbose
fi

gatherfollowers
geturls
downloadtracks

