#!/bin/bash

RECURSIONS=2
SRCARTIST=michaelred
curl https://soundcloud.com/${SRCARTIST}/following 2>>/dev/null| grep -Eo "itemprop=\"url\" href=\".*\"" | sed "s/itemprop=\"url\" href=\"\///" | sed "s/\"//" |tee  following-0.list
for NUM in $(seq 1 ${RECURSIONS});do
	for ARTIST in $(cat following-$(echo "${NUM}-1" | bc).list);do
		curl https://soundcloud.com/${ARTIST}/following 2>>/dev/null| grep -Eo "itemprop=\"url\" href=\".*\"" | sed "s/itemprop=\"url\" href=\"\///" | sed "s/\"//" |tee -a following-$NUM.list
	done
done
sort following-$RECURSIONS.list | uniq -c | sort -nr following-sorted.list
for LINE in $(cat following-sorted.list);do
	COUNT=$(echo $LINE | awk '{print $1}')
	ARTIST=$(echo $LINE | awk '{print $2}')
	echo "Rank: $COUNT              Artist Name:$ARTIST"
	echo "$ARTIST" >> sorted.list
done
rm following-[0-9].list

for ARTIST in $(cat sorted.list);do
	curl https://soundcloud.com/$ARTIST 2>>/dev/null| grep -Eo "itemprop=\"url\" href=\".*\"" | sed "s/itemprop=\"url\" href=\"/\"https:\/\/soundcloud\.com/"
	curl https://soundcloud.com/$ARTIST/reposts 2>>/dev/null| grep -Eo "itemprop=\"url\" href=\".*\"" | sed "s/itemprop=\"url\" href=\"/\"https:\/\/soundcloud\.com/"
	curl https://soundcloud.com/$ARTIST/sets 2>>/dev/null| grep -Eo "itemprop=\"url\" href=\".*\"" | sed "s/itemprop=\"url\" href=\"/\"https:\/\/soundcloud\.com/"
	curl https://soundcloud.com/$ARTIST/albums 2>>/dev/null| grep -Eo "itemprop=\"url\" href=\".*\"" | sed "s/itemprop=\"url\" href=\"/\"https:\/\/soundcloud\.com/"
	curl https://soundcloud.com/$ARTIST/tracks 2>>/dev/null| grep -Eo "itemprop=\"url\" href=\".*\"" | sed "s/itemprop=\"url\" href=\"/\"https:\/\/soundcloud\.com/"
done | sort | uniq | tee target-soundcloud-urls.list

cat target-soundcloud-urls.list | parallel --jobs=8 'youtube-dl {}'
rm sorted.list 2>>/dev/null
rm following-*.list 2>>/dev/null
rm target-soundcloud-urls.list 2>>/dev/null
