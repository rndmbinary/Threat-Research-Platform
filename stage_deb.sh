#!/bin/sh
check_account() {
	# This will check if the script was envoked using su
	if [[ $EUID -ne 0 ]]; then
		echo "This script must run using an elevated account. Exiting. . ."
		exit 1
	fi
}

stage_trp() {
	# Install lots of wares
	apt-get install -y apt-transport-https snapd neovim zsh git yara radare2 python3-pip p7zip-full less volatility tcpdump lynx host w3m libimage-exiftool-perl software-properties-common ranger whois bind9-host nodejs xpdf libemail-outlook-message-perl
	snap install powershell --classic
	curl -L https://www.npmjs.com/install.sh | sh
	npm install typescript
	pip3 install yara r2pipe requests scapy bs4 oletools pdfminer.six shodan

	# Install terminal customization
	sh -c "$(wget -O- https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
	git clone https://github.com/janjoswig/Ducula.git ~/.oh-my-zsh/custom/Ducula
	sed -i -e 's/ZSH_THEME\="\w+"/ZSH_THEME\="Ducula\/ducula"/g' ~/.zshrc
	sed -i -e 's/plugins\=\(git\)/plugins\=(git git-prompt command-not-found common-aliases encode64 history urltools\)/g' ~/.zshrc
	chown $USER ~/.zsh_history
	source ~/.zshrc

	# Install neovim customization
	git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.config/nvim/zsh-syntax-highlighting
        echo 'source ~/.config/nvim/zsh-syntax-highlighting/zsh-syntax-highlighting.plugin.zsh' >> ~/.zshrc

	# Install sleuthkit
	wget https://github.com/sleuthkit/sleuthkit/releases/download/sleuthkit-4.7.0/sleuthkit-4.7.0.tar.gz ~/
	7z xr sleuthkit-4.7.0.tar.gz

	# Install open source tools
	mkdir ~/git;
	git clone https://github.com/ReFirmLabs/binwalk.git ~/git/binwalk
	git clone https://github.com/mattgwwalker/msg-extractor.git ~/git/msg-extractor
	git clone https://github.com/laramies/theHarvester.git ~/git/theHarvester
	git clone https://github.com/pwndbg/pwndbg.git ~/git/pwndbg

	# Install osquery
	export OSQUERY_KEY=1484120AC4E9F8A1A577AEEE97A80C63C9D8B80B
	apt-key adv --keyserver keyserver.ubuntu.com --recv-keys $OSQUERY_KEY
	add-apt-repository 'deb [arch=amd64] https://pkg.osquery.io/deb deb main'
	apt-get update
	apt-get install -y osquery

}

check_account
stage_trp