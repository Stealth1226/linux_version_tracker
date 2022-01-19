#! /bin/bash

curl -s https://www.kernel.org/ > releases
pandoc +RTS -K1073741824 -RTS releases -f html -t markdown_github+pipe_tables -o releases.md

mkdir versions
touch new_releases
for i in mainline stable; do
	cat releases.md | grep $i: | awk '{ print $4 }' | sed s/'**'//g > versions/$i
done

cat releases.md | grep longterm: | awk '{ print $4 }' | sed s/'**'//g >> versions/longterm

for i in $(cat versions/longterm); do
	echo $i > versions/longterm-$(echo $i | cut -d . -f1-2)
done

for i in $(cat versions/mainline versions/stable versions/longterm-*); do
	grep -x $i releases_list || echo $i >> new_releases
done

cat versions/stable > releases_list
cat versions/mainline >> releases_list
cat versions/longterm >> releases_list
rm -rf versions

if [ -n "$(git status --porcelain)" ]; then export NEW_RELEASE=true && git add . &&  git commit -m "sync $(date +%d-%m-%y)" -m "$(cat new_releases)" && git push; else exit 0; fi

if [ "NEW_RELEASE" ]; then
	if [ -s new_releases ]; then
		### Send message to telegram ###
		wget https://raw.githubusercontent.com/fabianonline/telegram.sh/master/telegram
		sudo mv telegram /usr/bin
		sudo chmod +x /usr/bin/telegram
		UPDATE_MESSAGE=$(echo "*New Release Found!*")
		echo $TG_TOKEN > ~/.telegram.sh
		telegram -M "$UPDATE_MESSAGE"$'\n'"[$(cat new_releases)](https://git.kernel.org/pub/scm/linux/kernel/git/stable/linux.git/)"
	fi
fi
