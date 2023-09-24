#!/usr/bin/env bash
set -ueo pipefail
set -a

SRC_PATH="$(readlink -f "$(dirname "$0")")"

darker_channel() {
	value="$1"
	light_delta="$2"
	value_int="$(bc <<< "ibase=16; $value")"
	result="$(bc <<< "$value_int - $light_delta")"
	if [[ "$result" -lt 0 ]]; then
		result=0
	fi
	if [[ "$result" -gt 255 ]]; then
		result=255
	fi
	echo "$result"
}
mix_channel() {
	value1="$(printf '%03d' "0x$1")"
	value2="$(printf '%03d' "0x$2")"
	ratio="$3"
	result="$(bc <<< "scale=0; ($value1 * 100 * $ratio + $value2 * 100 * (1 - $ratio)) / 100")"
	if [[ "$result" -lt 0 ]]; then
		result=0
	elif [[ "$result" -gt 255 ]]; then
		result=255
	fi
	echo "$result"
}

darker() {
	hexinput="$(tr '[:lower:]' '[:upper:]' <<< "$1")"
	light_delta="${2-10}"

	a="$(cut -c-2 <<< "$hexinput")"
	b="$(cut -c3-4 <<< "$hexinput")"
	c="$(cut -c5-6 <<< "$hexinput")"

	r="$(darker_channel "$a" "$light_delta")"
	g="$(darker_channel "$b" "$light_delta")"
	b="$(darker_channel "$c" "$light_delta")"

	printf '%02x%02x%02x\n' "$r" "$g" "$b"
}
mix() {
	hexinput1="$(tr '[:lower:]' '[:upper:]' <<< "$1")"
	hexinput2="$(tr '[:lower:]' '[:upper:]' <<< "$2")"
	ratio="${3-0.5}"

	a="$(cut -c-2 <<< "$hexinput1")"
	b="$(cut -c3-4 <<< "$hexinput1")"
	c="$(cut -c5-6 <<< "$hexinput1")"
	d="$(cut -c-2 <<< "$hexinput2")"
	e="$(cut -c3-4 <<< "$hexinput2")"
	f="$(cut -c5-6 <<< "$hexinput2")"

	r="$(mix_channel "$a" "$d" "$ratio")"
	g="$(mix_channel "$b" "$e" "$ratio")"
	b="$(mix_channel "$c" "$f" "$ratio")"

	printf '%02x%02x%02x\n' "$r" "$g" "$b"
}
is_dark() {
	hexinput="$(tr '[:lower:]' '[:upper:]' <<< "$1")";
	half_darker="$(darker "$hexinput" 88)";
	[[ "$half_darker" == "000000" ]];
}

print_usage() {
	echo "usage: $0 [-o OUTPUT_THEME_NAME] [-a MESON_OPTS] PATH_TO_PRESET"
	echo
	echo "examples:"
	echo "	$0 --output my-theme-name <(echo -e \"BG=d8d8d8\\nFG=101010\\nHDR_BG=3c3c3c\\nHDR_FG=e6e6e6\\nSEL_BG=ad7fa8\\nSEL_FG=ffffff\\nTXT_BG=ffffff\\nTXT_FG=1a1a1a\\nBTN_BG=f5f5f5\\nBTN_FG=111111\\n\")"
	echo "	$0 ../colors/retro/twg"
	echo "	$0 --meson-opts '--quiet' ../colors/retro/clearlooks"
	exit 1
}

MESON_OPTS=""

while [[ "$#" -gt 0 ]]; do
	case "$1" in
		-o|--output)
			OUTPUT_THEME_NAME="$2"
			shift
			;;
		-a|--meson-opts)
			MESON_OPTS="${2}"
			shift
			;;
		*)
			if [[ "$1" == -* ]] || [[ "${THEME-}" ]]; then
				echo "unknown option $1"
				print_usage
				exit 2
			fi
			THEME="$1"
			;;
	esac
	shift
done

if [[ -z "${THEME:-}" ]]; then
	print_usage
fi

if [[ "$THEME" == */* ]] || [[ "$THEME" == *.* ]]; then
	echo "== Sourcing: $THEME"
	source "$THEME"
	THEME=$(basename "$THEME")
else
	if [[ -f "$SRC_PATH/../colors/$THEME" ]]; then
		echo "== Sourcing: $SRC_PATH/../colors/$THEME"
		source "$SRC_PATH/../colors/$THEME"
	else
		echo "== WARNING: Theme '$THEME' not found"
		exit 1
	fi
fi

if [[ $(date +"%m%d") = "0401" ]] && grep -q "no-jokes" <<< "$*"; then
	echo -e "\\n\\n== ERROR: Error patching uxtheme.dll\\n\\n"
	ACCENT_BG=000000 BG=C0C0C0 BTN_BG=C0C0C0 BTN_FG=000000 FG=000000
	HDR_BTN_BG=C0C0C0 HDR_BTN_FG=000000 HDR_BG=C0C0C0
	HDR_FG=000000 SEL_BG=000080 SEL_FG=FFFFFF TXT_BG=FFFFFF TXT_FG=000000
fi

HDR_BG=${HDR_BG-$MENU_BG}
HDR_FG=${HDR_FG-$MENU_FG}
ARC_TRANSPARENCY=$(tr '[:upper:]' '[:lower:]' <<< "${ARC_TRANSPARENCY-True}")
ARC_WIDGET_BORDER_COLOR=${ARC_WIDGET_BORDER_COLOR-$(mix ${BG} ${FG} 0.75)}
TXT_FG=$FG
BTN_FG=$FG
HDR_BTN_FG=$HDR_FG
ACCENT_BG=${ACCENT_BG-$SEL_BG}
HDR_BTN_BG=${HDR_BTN_BG-$BTN_BG}
HDR_BTN_FG=${HDR_BTN_FG-$BTN_FG}
WM_BORDER_FOCUS=${WM_BORDER_FOCUS-$SEL_BG}
WM_BORDER_UNFOCUS=${WM_BORDER_UNFOCUS-$HDR_BG}
SPACING=${SPACING-3}
GRADIENT=${GRADIENT-0}
ROUNDNESS=${ROUNDNESS-2}
TERMINAL_COLOR1=${TERMINAL_COLOR1:-F04A50}
TERMINAL_COLOR3=${TERMINAL_COLOR3:-F08437}
TERMINAL_COLOR4=${TERMINAL_COLOR4:-1E88E5}
TERMINAL_COLOR5=${TERMINAL_COLOR5:-E040FB}
TERMINAL_COLOR9=${TERMINAL_COLOR9:-DD2C00}
TERMINAL_COLOR10=${TERMINAL_COLOR10:-00C853}
TERMINAL_COLOR11=${TERMINAL_COLOR11:-FF6D00}
TERMINAL_COLOR12=${TERMINAL_COLOR12:-66BB6A}
INACTIVE_FG=$(mix "$FG" "$BG" 0.75)
INACTIVE_BG=$(mix "$BG" "$FG" 0.75)
INACTIVE_HDR_FG=$(mix "$HDR_FG" "$HDR_BG" 0.75)
INACTIVE_HDR_BG=$(mix "$HDR_BG" "$HDR_FG" 0.75)
INACTIVE_TXT_MIX=$(mix "$TXT_FG" "$TXT_BG")
INACTIVE_TXT_FG=$(mix "$TXT_FG" "$TXT_BG" 0.75)
INACTIVE_TXT_BG=$(mix "$TXT_BG" "$BG" 0.75)
OUTPUT_THEME_NAME=${OUTPUT_THEME_NAME-oomox-arc-$THEME}
DEST_PATH="$HOME/.themes/${OUTPUT_THEME_NAME/\//-}"

if [[ "$SRC_PATH" == "$DEST_PATH" ]]; then
	echo "== ERROR: can't put Source path as Destination."
	exit 1
fi

if [[ ! -d "$(dirname "${DEST_PATH}")" ]] ; then
	mkdir -p "${DEST_PATH}"
fi

tempdir=$(mktemp -d)
post_clean_up() {
	rm -r "$tempdir"
}
trap post_clean_up EXIT SIGHUP SIGINT SIGTERM

cp -r "$SRC_PATH/"* "$tempdir/"
cd "$tempdir"
LOG_BASENAME="$(dirname "$PWD/." | sed 's/^.*\///')"
touch "/tmp/$LOG_BASENAME.log"
echo "!== DETAILED LOG AT: "/tmp/$LOG_BASENAME.log" ==!"

echo "== Converting theme into template..."

PATHLIST=(
	'./common/'
)

multiple_cmd_template() {
	test -n "$(sed -i 's/#cfd6e6/%ARC_WIDGET_BORDER_COLOR%/gI;/%ARC_WIDGET_BORDER_COLOR%/e echo yes >&2' $1 2>&1)" && echo "$1: #cfd6e6 replaced by %ARC_WIDGET_BORDER_COLOR%";
	test -n "$(sed -i 's/#f5f6f7/%BG%/gI;/%BG%/e echo yes >&2' $1 2>&1)" && echo "$1: #f5f6f7 replaced by %BG%";
	test -n "$(sed -i 's/#dde3e9/%BG_DARKER%/gI;/%BG_DARKER%/e echo yes >&2' $1 2>&1)" && echo "$1: #dde3e9 replaced by %BG_DARKER%";
	test -n "$(sed -i 's/#3b3e45/%FG%/gI;/%FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #3b3e45 replaced by %FG%";
	test -n "$(sed -i 's/#FFFFFF/%TXT_BG%/gI;/%TXT_BG%/e echo yes >&2' $1 2>&1)" && echo "$1: #FFFFFF replaced by %TXT_BG%";
	test -n "$(sed -i 's/#3b3e45/%TXT_FG%/gI;/%TXT_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #3b3e45 replaced by %TXT_FG%";
	test -n "$(sed -i 's/#5294e2/%SEL_BG%/gI;/%SEL_BG%/e echo yes >&2' $1 2>&1)" && echo "$1: #5294e2 replaced by %SEL_BG%";
	test -n "$(sed -i 's/#fcfdfd/%BTN_BG%/gI;/%BTN_BG%/e echo yes >&2' $1 2>&1)" && echo "$1: #fcfdfd replaced by %BTN_BG%";
	test -n "$(sed -i 's/#e7e8eb/%HDR_BG%/gI;/%HDR_BG%/e echo yes >&2' $1 2>&1)" && echo "$1: #e7e8eb replaced by %HDR_BG%";
	test -n "$(sed -i 's/#2f343f/%HDR_BG%/gI;/%HDR_BG%/e echo yes >&2' $1 2>&1)" && echo "$1: #2f343f replaced by %HDR_BG%";
	test -n "$(sed -i 's/#D3DAE3/%HDR_FG%/gI;/%HDR_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #D3DAE3 replaced by %HDR_FG%";
	test -n "$(sed -i 's/#fbfcfc/%INACTIVE_BG%/gI;/%INACTIVE_BG%/e echo yes >&2' $1 2>&1)" && echo "$1: #fbfcfc replaced by %INACTIVE_BG%";
	test -n "$(sed -i 's/#a9acb2/%INACTIVE_FG%/gI;/%INACTIVE_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #a9acb2 replaced by %INACTIVE_FG%";
	test -n "$(sed -i 's/#e2e7ef/%BG_DARKER%/gI;/%BG_DARKER%/e echo yes >&2' $1 2>&1)" && echo "$1: #e2e7ef replaced by %BG_DARKER%";
	test -n "$(sed -i 's/#F04A50/%TERMINAL_COLOR1%/gI;/%TERMINAL_COLOR1%/e echo yes >&2' $1 2>&1)" && echo "$1: #F04A50 replaced by %TERMINAL_COLOR1%";
	test -n "$(sed -i 's/#F08437/%TERMINAL_COLOR3%/gI;/%TERMINAL_COLOR3%/e echo yes >&2' $1 2>&1)" && echo "$1: #F08437 replaced by %TERMINAL_COLOR3%";
	test -n "$(sed -i 's/#FC4138/%TERMINAL_COLOR9%/gI;/%TERMINAL_COLOR9%/e echo yes >&2' $1 2>&1)" && echo "$1: #FC4138 replaced by %TERMINAL_COLOR9%";
	test -n "$(sed -i 's/#73d216/%TERMINAL_COLOR10%/gI;/%TERMINAL_COLOR10%/e echo yes >&2' $1 2>&1)" && echo "$1: #73d216 replaced by %TERMINAL_COLOR10%";
	test -n "$(sed -i 's/#F27835/%TERMINAL_COLOR11%/gI;/%TERMINAL_COLOR11%/e echo yes >&2' $1 2>&1)" && echo "$1: #F27835 replaced by %TERMINAL_COLOR11%";
	test -n "$(sed -i 's/#4DADD4/%TERMINAL_COLOR12%/gI;/%TERMINAL_COLOR12%/e echo yes >&2' $1 2>&1)" && echo "$1: #4DADD4 replaced by %TERMINAL_COLOR12%";
	test -n "$(sed -i 's/#353945/%HDR_BG2%/gI;/%HDR_BG2%/e echo yes >&2' $1 2>&1)" && echo "$1: #353945 replaced by %HDR_BG2%";
	test -n "$(sed -i 's/Name=Arc/Name=%OUTPUT_THEME_NAME%/g;/Name=%OUTPUT_THEME_NAME%/e echo yes >&2' $1 2>&1)" && echo "$1: Name=Arc replaced by Name=%OUTPUT_THEME_NAME%";
	test -n "$(sed -i 's/#f46067/%TERMINAL_COLOR9%/gI;/%TERMINAL_COLOR9%/e echo yes >&2' $1 2>&1)" && echo "$1: #f46067 replaced by %TERMINAL_COLOR9%";
	test -n "$(sed -i 's/#cc575d/%TERMINAL_COLOR9%/gI;/%TERMINAL_COLOR9%/e echo yes >&2' $1 2>&1)" && echo "$1: #cc575d replaced by %TERMINAL_COLOR9%";
	test -n "$(sed -i 's/#f68086/%TERMINAL_COLOR9_LIGHTER%/gI;/%TERMINAL_COLOR9_LIGHTER%/e echo yes >&2' $1 2>&1)" && echo "$1: #f68086 replaced by %TERMINAL_COLOR9_LIGHTER%";
	test -n "$(sed -i 's/#d7787d/%TERMINAL_COLOR9_LIGHTER%/gI;/%TERMINAL_COLOR9_LIGHTER%/e echo yes >&2' $1 2>&1)" && echo "$1: #d7787d replaced by %TERMINAL_COLOR9_LIGHTER%";
	test -n "$(sed -i 's/#f13039/%TERMINAL_COLOR9_DARKER%/gI;/%TERMINAL_COLOR9_DARKER%/e echo yes >&2' $1 2>&1)" && echo "$1: #f13039 replaced by %TERMINAL_COLOR9_DARKER%";
	test -n "$(sed -i 's/#be3841/%TERMINAL_COLOR9_DARKER%/gI;/%TERMINAL_COLOR9_DARKER%/e echo yes >&2' $1 2>&1)" && echo "$1: #be3841 replaced by %TERMINAL_COLOR9_DARKER%";
	test -n "$(sed -i 's/#F8F8F9/%HDR_FG%/gI;/%HDR_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #F8F8F9 replaced by %HDR_FG%";
	test -n "$(sed -i 's/#fdfdfd/%HDR_FG%/gI;/%HDR_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #fdfdfd replaced by %HDR_FG%";
	test -n "$(sed -i 's/#454C5C/%HDR_FG%/gI;/%HDR_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #454C5C replaced by %HDR_FG%";
	test -n "$(sed -i 's/#D1D3DA/%HDR_FG%/gI;/%HDR_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #D1D3DA replaced by %HDR_FG%";
	test -n "$(sed -i 's/#90949E/%HDR_FG%/gI;/%HDR_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #90949E replaced by %HDR_FG%";
	test -n "$(sed -i 's/#90939B/%HDR_FG%/gI;/%HDR_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #90939B replaced by %HDR_FG%";
	test -n "$(sed -i 's/#B6B8C0/%INACTIVE_HDR_FG%/gI;/%INACTIVE_HDR_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #B6B8C0 replaced by %INACTIVE_HDR_FG%";
	test -n "$(sed -i 's/#666A74/%INACTIVE_HDR_FG%/gI;/%INACTIVE_HDR_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #666A74 replaced by %INACTIVE_HDR_FG%";
	test -n "$(sed -i 's/#7A7F8B/%INACTIVE_HDR_FG%/gI;/%INACTIVE_HDR_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #7A7F8B replaced by %INACTIVE_HDR_FG%";
	test -n "$(sed -i 's/#C4C7CC/%INACTIVE_HDR_FG%/gI;/%INACTIVE_HDR_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #C4C7CC replaced by %INACTIVE_HDR_FG%";
	test -n "$(sed -i 's/#BAC3CF/%HDR_FG%/gI;/%HDR_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #BAC3CF replaced by %HDR_FG%";
	test -n "$(sed -i 's/#4B5162/%TXT_FG%/gI;/%TXT_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #4B5162 replaced by %TXT_FG%";
	test -n "$(sed -i 's/#AFB8C5/%HDR_FG%/gI;/%HDR_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #AFB8C5 replaced by %HDR_FG%";
	test -n "$(sed -i 's/#404552/%HDR_BG%/gI;/%HDR_BG%/e echo yes >&2' $1 2>&1)" && echo "$1: #404552 replaced by %HDR_BG%";
	test -n "$(sed -i 's/#383C4A/%HDR_BG%/gI;/%HDR_BG%/e echo yes >&2' $1 2>&1)" && echo "$1: #383C4A replaced by %HDR_BG%";
	test -n "$(sed -i 's/#5c616c/%FG%/gI;/%FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #5c616c replaced by %FG%";
	test -n "$(sed -i 's/#d3d8e2/%SEL_BG%/gI;/%SEL_BG%/e echo yes >&2' $1 2>&1)" && echo "$1: #d3d8e2 replaced by %SEL_BG%";
	test -n "$(sed -i 's/#b7c0d3/%SEL_BG%/gI;/%SEL_BG%/e echo yes >&2' $1 2>&1)" && echo "$1: #b7c0d3 replaced by %SEL_BG%";
	test -n "$(sed -i 's/#cbd2e3/%ARC_WIDGET_BORDER_COLOR%/gI;/%ARC_WIDGET_BORDER_COLOR%/e echo yes >&2' $1 2>&1)" && echo "$1: #cbd2e3 replaced by %ARC_WIDGET_BORDER_COLOR%";
	test -n "$(sed -i 's/#fcfcfc/%TXT_BG%/gI;/%TXT_BG%/e echo yes >&2' $1 2>&1)" && echo "$1: #fcfcfc replaced by %TXT_BG%";
	test -n "$(sed -i 's/#dbdfe3/%INACTIVE_TXT_BG%/gI;/%INACTIVE_TXT_BG%/e echo yes >&2' $1 2>&1)" && echo "$1: #dbdfe3 replaced by %INACTIVE_TXT_BG%";
	test -n "$(sed -i 's/#eaebed/%INACTIVE_TXT_BG%/gI;/%INACTIVE_TXT_BG%/e echo yes >&2' $1 2>&1)" && echo "$1: #eaebed replaced by %INACTIVE_TXT_BG%";
	test -n "$(sed -i 's/#b8babf/%INACTIVE_TXT_MIX%/gI;/%INACTIVE_TXT_MIX%/e echo yes >&2' $1 2>&1)" && echo "$1: #b8babf replaced by %INACTIVE_TXT_MIX%";
	test -n "$(sed -i 's/#d3d4d8/%INACTIVE_TXT_FG%/gI;/%INACTIVE_TXT_FG%/e echo yes >&2' $1 2>&1)" && echo "$1: #d3d4d8 replaced by %INACTIVE_TXT_FG%";
	test -n "$(sed -i 's/#d7d8dd/%HDR_BG2%/gI;/%HDR_BG2%/e echo yes >&2' $1 2>&1)" && echo "$1: #d7d8dd replaced by %HDR_BG2%";
	test -n "$(sed -i 's/#262932/%HDR_BG2%/gI;/%HDR_BG2%/e echo yes >&2' $1 2>&1)" && echo "$1: #262932 replaced by %HDR_BG2%";
};
for FILEPATH in "${PATHLIST[@]}"; do
	find "$FILEPATH" -type f -exec bash -c 'multiple_cmd_template "$0"' {} \; >> "/tmp/$LOG_BASENAME.log"
done

if [[ "${DEBUG:-}" ]]; then
	echo "You can debug TEMP DIR: $tempdir, press [Enter] when finished"
	read -r answer
	if [[ "${answer}" = "q" ]] ; then
		exit 125
	fi
fi

while IFS= read -r -d '' template_file
do
	cat "${template_file}" >> "${template_file::-5}"
done < <(find ./common -name '*.thpl' -print0)

ASSETS_FILES=(
	'./common/gtk-2.0/assets-dark/assets.svg'
	'./common/gtk-2.0/assets-light/assets.svg'
	'./common/gtk-3.0/assets/assets.svg'
	'./common/gtk-4.0/assets/assets.svg'
)

echo "== Processing Assets files..."
for assets_file in "${ASSETS_FILES[@]}"; do
	test -n "$(sed -i 's/%SEL_BG%/%ACCENT_BG%/gI;/%ACCENT_BG%/e echo yes >&2' "${assets_file}" 2>&1)" && echo "${assets_file}: %SEL_BG% replaced by %ACCENT_BG%" >> "/tmp/$LOG_BASENAME.log"
done

echo "== Filling the template with the new colorscheme..."

multiple_cmd_colorscheme() {
	test -n "$(sed -i 's/%ARC_WIDGET_BORDER_COLOR%/#'"$ARC_WIDGET_BORDER_COLOR"'/g;/#'"$ARC_WIDGET_BORDER_COLOR"'/e echo yes >&2' $1 2>&1)" && echo "$1: %ARC_WIDGET_BORDER_COLOR% replaced by #'"$ARC_WIDGET_BORDER_COLOR"'";
	test -n "$(sed -i 's/%BG%/#'"$BG"'/g;/#'"$BG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %BG% replaced by #'"$BG"'";
	test -n "$(sed -i 's/%BG_DARKER%/#'"$(darker $BG)"'/g;/#'"$(darker $BG)"'/e echo yes >&2' $1 2>&1)" && echo "$1: %BG_DARKER% replaced by #'"$(darker $BG)"'";
	test -n "$(sed -i 's/%FG%/#'"$FG"'/g;/#'"$FG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %FG% replaced by #'"$FG"'";
	test -n "$(sed -i 's/%ACCENT_BG%/#'"$ACCENT_BG"'/g;/#'"$ACCENT_BG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %ACCENT_BG% replaced by #'"$ACCENT_BG"'";
	test -n "$(sed -i 's/%SEL_BG%/#'"$SEL_BG"'/g;/#'"$SEL_BG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %SEL_BG% replaced by #'"$SEL_BG"'";
	test -n "$(sed -i 's/%SEL_FG%/#'"$SEL_FG"'/g;/#'"$SEL_FG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %SEL_FG% replaced by #'"$SEL_FG"'";
	test -n "$(sed -i 's/%TXT_BG%/#'"$TXT_BG"'/g;/#'"$TXT_BG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %TXT_BG% replaced by #'"$TXT_BG"'";
	test -n "$(sed -i 's/%TXT_FG%/#'"$TXT_FG"'/g;/#'"$TXT_FG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %TXT_FG% replaced by #'"$TXT_FG"'";
	test -n "$(sed -i 's/%HDR_BG%/#'"$HDR_BG"'/g;/#'"$HDR_BG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %HDR_BG% replaced by #'"$HDR_BG"'";
	test -n "$(sed -i 's/%HDR_BG2%/#'"$(mix $HDR_BG $BG 0.85)"'/g;/#'"$(mix $HDR_BG $BG 0.85)"'/e echo yes >&2' $1 2>&1)" && echo "$1: %HDR_BG2% replaced by #'"$(mix $HDR_BG $BG 0.85)"'";
	test -n "$(sed -i 's/%HDR_FG%/#'"$HDR_FG"'/g;/#'"$HDR_FG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %HDR_FG% replaced by #'"$HDR_FG"'";
	test -n "$(sed -i 's/%BTN_BG%/#'"$BTN_BG"'/g;/#'"$BTN_BG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %BTN_BG% replaced by #'"$BTN_BG"'";
	test -n "$(sed -i 's/%BTN_FG%/#'"$BTN_FG"'/g;/#'"$BTN_FG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %BTN_FG% replaced by #'"$BTN_FG"'";
	test -n "$(sed -i 's/%HDR_BTN_BG%/#'"$HDR_BTN_BG"'/g;/#'"$HDR_BTN_BG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %HDR_BTN_BG% replaced by #'"$HDR_BTN_BG"'";
	test -n "$(sed -i 's/%HDR_BTN_FG%/#'"$HDR_BTN_FG"'/g;/#'"$HDR_BTN_FG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %HDR_BTN_FG% replaced by #'"$HDR_BTN_FG"'";
	test -n "$(sed -i 's/%WM_BORDER_FOCUS%/#'"$WM_BORDER_FOCUS"'/g;/#'"$WM_BORDER_FOCUS"'/e echo yes >&2' $1 2>&1)" && echo "$1: %WM_BORDER_FOCUS% replaced by #'"$WM_BORDER_FOCUS"'";
	test -n "$(sed -i 's/%WM_BORDER_UNFOCUS%/#'"$WM_BORDER_UNFOCUS"'/g;/#'"$WM_BORDER_UNFOCUS"'/e echo yes >&2' $1 2>&1)" && echo "$1: %WM_BORDER_UNFOCUS% replaced by #'"$WM_BORDER_UNFOCUS"'";
	test -n "$(sed -i 's/%SPACING%/'"$SPACING"'/g;/'"$SPACING"'/e echo yes >&2' $1 2>&1)" && echo "$1: %SPACING% replaced by '"$SPACING"'";
	test -n "$(sed -i 's/%INACTIVE_FG%/#'"$INACTIVE_FG"'/g;/#'"$INACTIVE_FG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %INACTIVE_FG% replaced by #'"$INACTIVE_FG"'";
	test -n "$(sed -i 's/%INACTIVE_BG%/#'"$INACTIVE_BG"'/g;/#'"$INACTIVE_BG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %INACTIVE_BG% replaced by #'"$INACTIVE_BG"'";
	test -n "$(sed -i 's/%INACTIVE_TXT_MIX%/#'"$INACTIVE_TXT_MIX"'/g;/#'"$INACTIVE_TXT_MIX"'/e echo yes >&2' $1 2>&1)" && echo "$1: %INACTIVE_TXT_MIX% replaced by #'"$INACTIVE_TXT_MIX"'";
	test -n "$(sed -i 's/%INACTIVE_TXT_FG%/#'"$INACTIVE_TXT_FG"'/g;/#'"$INACTIVE_TXT_FG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %INACTIVE_TXT_FG% replaced by #'"$INACTIVE_TXT_FG"'";
	test -n "$(sed -i 's/%INACTIVE_TXT_BG%/#'"$INACTIVE_TXT_BG"'/g;/#'"$INACTIVE_TXT_BG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %INACTIVE_TXT_BG% replaced by #'"$INACTIVE_TXT_BG"'";
	test -n "$(sed -i 's/%INACTIVE_HDR_FG%/#'"$INACTIVE_HDR_FG"'/g;/#'"$INACTIVE_HDR_FG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %INACTIVE_HDR_FG% replaced by #'"$INACTIVE_HDR_FG"'";
	test -n "$(sed -i 's/%INACTIVE_HDR_BG%/#'"$INACTIVE_HDR_BG"'/g;/#'"$INACTIVE_HDR_BG"'/e echo yes >&2' $1 2>&1)" && echo "$1: %INACTIVE_HDR_BG% replaced by #'"$INACTIVE_HDR_BG"'";
	test -n "$(sed -i 's/%TERMINAL_COLOR1%/#'"$TERMINAL_COLOR1"'/g;/#'"$TERMINAL_COLOR1"'/e echo yes >&2' $1 2>&1)" && echo "$1: %TERMINAL_COLOR1% replaced by #'"$TERMINAL_COLOR1"'";
	test -n "$(sed -i 's/%TERMINAL_COLOR3%/#'"$TERMINAL_COLOR3"'/g;/#'"$TERMINAL_COLOR3"'/e echo yes >&2' $1 2>&1)" && echo "$1: %TERMINAL_COLOR3% replaced by #'"$TERMINAL_COLOR3"'";
	test -n "$(sed -i 's/%TERMINAL_COLOR4%/#'"$TERMINAL_COLOR4"'/g;/#'"$TERMINAL_COLOR4"'/e echo yes >&2' $1 2>&1)" && echo "$1: %TERMINAL_COLOR4% replaced by #'"$TERMINAL_COLOR4"'";
	test -n "$(sed -i 's/%TERMINAL_COLOR5%/#'"$TERMINAL_COLOR5"'/g;/#'"$TERMINAL_COLOR5"'/e echo yes >&2' $1 2>&1)" && echo "$1: %TERMINAL_COLOR5% replaced by #'"$TERMINAL_COLOR5"'";
	test -n "$(sed -i 's/%TERMINAL_COLOR9%/#'"$TERMINAL_COLOR9"'/g;/#'"$TERMINAL_COLOR9"'/e echo yes >&2' $1 2>&1)" && echo "$1: %TERMINAL_COLOR9% replaced by #'"$TERMINAL_COLOR9"'";
	test -n "$(sed -i 's/%TERMINAL_COLOR9_DARKER%/#'"$(darker "$TERMINAL_COLOR9" 10)"'/g;/#'"$(darker "$TERMINAL_COLOR9" 10)"'/e echo yes >&2' $1 2>&1)" && echo "$1: %TERMINAL_COLOR9_DARKER% replaced by #'"$(darker "$TERMINAL_COLOR9" 10)"'";
	test -n "$(sed -i 's/%TERMINAL_COLOR9_LIGHTER%/#'"$(darker "$TERMINAL_COLOR9" -10)"'/g;/#'"$(darker "$TERMINAL_COLOR9" -10)"'/e echo yes >&2' $1 2>&1)" && echo "$1: %TERMINAL_COLOR9_LIGHTER% replaced by #'"$(darker "$TERMINAL_COLOR9" -10)"'";
	test -n "$(sed -i 's/%TERMINAL_COLOR10%/#'"$TERMINAL_COLOR10"'/g;/#'"$TERMINAL_COLOR10"'/e echo yes >&2' $1 2>&1)" && echo "$1: %TERMINAL_COLOR10% replaced by #'"$TERMINAL_COLOR10"'";
	test -n "$(sed -i 's/%TERMINAL_COLOR11%/#'"$TERMINAL_COLOR11"'/g;/#'"$TERMINAL_COLOR11"'/e echo yes >&2' $1 2>&1)" && echo "$1: %TERMINAL_COLOR11% replaced by #'"$TERMINAL_COLOR11"'";
	test -n "$(sed -i 's/%TERMINAL_COLOR12%/#'"$TERMINAL_COLOR12"'/g;/#'"$TERMINAL_COLOR12"'/e echo yes >&2' $1 2>&1)" && echo "$1: %TERMINAL_COLOR12% replaced by #'"$TERMINAL_COLOR12"'";
	test -n "$(sed -i 's/%OUTPUT_THEME_NAME%/'"$OUTPUT_THEME_NAME"'/g;/'"$OUTPUT_THEME_NAME"'/e echo yes >&2' $1 2>&1)" && echo "$1: %OUTPUT_THEME_NAME% replaced by '"$OUTPUT_THEME_NAME"'";
};
for FILEPATH in "${PATHLIST[@]}"; do
	find "$FILEPATH" -type f -exec bash -c 'multiple_cmd_colorscheme "$0"' {} \; >> "/tmp/$LOG_BASENAME.log"
done

if [[ "$ARC_TRANSPARENCY" == "false" ]]; then
	if [[ -z "${MESON_OPTS}" ]]; then
		MESON_OPTS="-Dtransparency=false"
	else
		MESON_OPTS="${MESON_OPTS} -Dtransparency=false"
	fi
fi

echo "== Making theme..."
mkdir distrib
PREF_DIR="$(readlink -e ./distrib/)"
echo "== Final command is: meson setup --prefix=\"$PREF_DIR\" -Dthemes=gtk2,gtk3,gtk4 -Dvariants=light,darker,dark,lighter \"${MESON_OPTS}\" build/"
meson setup --prefix="$PREF_DIR" -Dthemes=gtk2,gtk3,gtk4 -Dvariants=light,darker,dark,lighter "${MESON_OPTS}" build/ >> "/tmp/$LOG_BASENAME.log"
meson install -C build/ >> "/tmp/$LOG_BASENAME.log"
echo

echo
rm -fr "${DEST_PATH}"
if [[ "$ARC_TRANSPARENCY" == "false" ]]; then
	mv ./distrib/share/themes/Arc-Darker-solid "${DEST_PATH}"
else
	mv ./distrib/share/themes/Arc-Darker "${DEST_PATH}"
fi

cd "${DEST_PATH}"
sed -i "s/=Arc.*\$/=$OUTPUT_THEME_NAME/g" ./index.theme
cp -f ./gtk-2.0/assets/focus-line.png ./gtk-2.0/assets/frame.png
cp -f ./gtk-2.0/assets/null.png ./gtk-2.0/assets/frame-gap-start.png
cp -f ./gtk-2.0/assets/null.png ./gtk-2.0/assets/frame-gap-end.png
cp -f ./gtk-2.0/assets/null.png ./gtk-2.0/assets/line-v.png
cp -f ./gtk-2.0/assets/null.png ./gtk-2.0/assets/line-h.png

echo "== Finished Successfully: meson setup --prefix=\"$PREF_DIR\" -Dthemes=gtk2,gtk3,gtk4 -Dvariants=light,darker,dark,lighter \"${MESON_OPTS}\" build/"
echo "== The theme was installed into ${DEST_PATH} folder."
echo "!== DETAILED LOG AT: "/tmp/$LOG_BASENAME.log" ==!"
echo
exit 0
