if perl -v >/dev/null 2>/dev/null; then
	RESET=`perl -e 'print("\e[0m")'`
	BOLD=`perl -e 'print("\e[1m")'`
	YELLOW=`perl -e 'print("\e[33m")'`
	BLUE_BG=`perl -e 'print("\e[44m")'`
elif python -V >/dev/null 2>/dev/null; then
	RESET=`echo 'import sys; sys.stdout.write("\033[0m")' | python`
	BOLD=`echo 'import sys; sys.stdout.write("\033[1m")' | python`
	YELLOW=`echo 'import sys; sys.stdout.write("\033[33m")' | python`
	BLUE_BG=`echo 'import sys; sys.stdout.write("\033[44m")' | python`
else
	RESET=
	BOLD=
	YELLOW=
	BLUE_BG=
fi

function header()
{
	local title="$1"
	echo
	echo "${BLUE_BG}${YELLOW}${BOLD}${title}${RESET}"
	echo "------------------------------------------"
}

function run()
{
	echo "+ $@"
	"$@"
}

function download_and_extract()
{
	local BASENAME="$1"
	local DIRNAME="$2"
	local URL="$3"
	local regex='\.bz2$'

	if [[ ! -e "/tmp/$BASENAME" ]]; then
		run rm -f "/tmp/$BASENAME.tmp"
		run curl --fail -L -o "/tmp/$BASENAME.tmp" "$URL"
		run mv "/tmp/$BASENAME.tmp" "/tmp/$BASENAME"
	fi
	if [[ "$URL" =~ $regex ]]; then
		run tar xjf "/tmp/$BASENAME"
	else
		run tar xzf "/tmp/$BASENAME"
	fi

	echo "Entering $RUNTIME_DIR/$DIRNAME"
	pushd "$DIRNAME" >/dev/null
}

function create_user()
{
	local name="$1"
	local full_name="$2"
	local id="$3"
	create_group $name $id
	if ! grep -q "^$name:" /etc/passwd; then
		adduser --uid $id --gid $id --comment "$full_name" $name
	fi
	usermod -L $name
}

function create_group()
{
	local name="$1"
	local id="$2"
	if ! grep -q "^$name:" /etc/group >/dev/null; then
		groupadd --gid $id $name
	fi
}
