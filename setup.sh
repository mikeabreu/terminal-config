#!/bin/bash
#
#   System Configuration
#   Author: Mike Abreu
#
#   This is a script that was created to quickly configure Kali/Debian Linux
#   terminal environments to reflect my own configuration.
#
################################################################################
main() {
    if [ $1 == '-y' ]; then
        echo "no confirmation mode"
    else
        echo "This script requires sudo privileges or to be run as root"
        sudo whoami
        clear
        # Display version of sysconfig
        display_info "This is the headless server configuration."
        # Display confirmation
        display_script_confirmation
    fi

    # Set variables
    TUSR=$(whoami)
    CWD=$(dirname $0)

    display_success "Updating git submodules"
    git submodule update --init

    # remove 'env zsh' line in install.sh script for oh-my-zsh
    sed -i 's/env zsh/#env zsh/g' oh-my-zsh/tools/install.sh || echo "Failed removing env zsh"
    # remove 'chsh' line in install script
    sed -i 's/chsh -s/#chsh -s/g' oh-my-zsh/tools/install.sh || echo "Failed removing chsh"

    # Create all required file locations
    create_directory "${HOME}/bin"
    create_directory "${HOME}/.grc"
    create_directory "${HOME}/.config/terminator/"
    create_directory "${HOME}/.vim/bundle"
    create_directory "${HOME}/.vim/colors"
    reset_home_dir_permissions

    # STEP 1: Install ZSH, GRC, VIM and TERMINATOR
    sudo apt-get update
    install_apt_package "zsh"
    install_apt_package "vim"
    install_apt_package "grc"
    install_apt_package "fonts-powerline"
    install_apt_package "git"
    install_apt_package "htop"
    install_apt_package "axel"
    install_apt_package "curl"
    install_apt_package "wget"
    install_apt_package "ipsets"
    install_apt_package "fail2ban"

    # STEP 2: Install Oh-My-ZSH
    install_oh_my_zsh

    # STEP 3: Configure Theme for ZSH
    display_success "Configuring Spacheship: ${CWHITE}Oh-My-ZSH"
    install_spaceship_theme

    configure_zshrc
    configure_grc

    # STEP 6: Install Vim/Vundle
    install_vundle
    configure_vim

    install_cheatsheet

    display_success "System Configuration Finished"
    reset_home_dir_permissions
    env zsh
}
################################################################################
#   FUNCTIONS
################################################################################
display_help() {
    echo -e """${CORANGE}
    Terminal Customization Script

    Usage:${CE}${CBLUE} tconfig.sh${CORANGE}

    This script was built to help automate the process of customizing a users
    terminal. The target configuration to run this script in is a fresh install.
    The script is safe to your existing configurations and copies them to the
    same file name and location with .bkp appended. Example: ~/.zshrc.bkp
    ${CORANGE}
    Example:${CE}
        ${CBLUE}tconfig.sh${CE}
    """
    exit 0
}
################################################################################
display_info() {
    echo
    display_bar $CBLUE
    echo -e "${CBLUE}[*]${CE} ${1}${CE}"
    display_bar $CBLUE
}
display_message() {
    echo -e "${CGREEN}[+]${CE} ${1}${CE}"
}
display_success() {
    echo
    display_bar $CGREEN
    echo -e "${CGREEN}[+]${CE} ${1}${CE}"
    display_bar $CGREEN
}
display_warning() {
    echo
    display_bar $CYELLOW
    echo -e "${CYELLOW}[!]${CE} ${1}${CE}"
    display_bar $CYELLOW
}
display_error() {
    echo
    display_bar $CRED
    echo -e "${CRED}[-]${CE} ${1}${CE}"
    display_bar $CRED
}
display_bar() {
    echo -e "${1}====================================================================================================${CE}"
}
################################################################################
prompt_confirmation() {
    echo
    echo -en "${CYELLOW}[!]${CE} $1  ${CYELLOW}${2}${CE}  "
    read -r response
    case $response in
        [yY]|[yY][eE][sS])
            false
            ;;
        *)
            exit 1
            ;;
    esac
}
################################################################################
display_script_confirmation() {
    display_bar $CYELLOW
    echo -e "${CYELLOW}[!]${CE} This script will install software to your operating system and change configurations.${CE}"
    echo
    echo -e "    For a full list of software and configuration changes see ${CBLUE}https://github.com/mikeabreu/tconfig${CE}"
    echo
    echo -e "    ${CRED}CTRL+C to exit the script during execution.${CE}"
    display_bar $CYELLOW
    prompt_confirmation "Are you sure that you wish to continue?" "[y/N]"
}
################################################################################
create_directory() {
    if [[ ! -e $1 ]]; then
        display_message "Creating Directory:${CWHITE} $1"
        sudo mkdir -vp $1
    fi
}
################################################################################
safe_copy() {
    if [[ -e $2 ]]; then
        safe_backup $2
    fi
    sudo cp -av "${1}" "${2}"
}
copy_recursive() {
    sudo cp -av -r "${1}" "${2}"
}
################################################################################
safe_backup() {
    if [[ -e $1 ]]; then
        sudo cp -av "${1}" "${1}.bkp"
    fi
}
################################################################################
configure_zshrc() {
    safe_copy "${CWD}/configs/zsh/.zshrc" "${HOME}/.zshrc"
}
################################################################################
configure_grc() {
    display_success "Configuring GRC"
    copy_recursive "${CWD}/configs/grc/conf/*" "/usr/share/grc/"
    safe_copy "${CWD}/configs/grc/grc.conf" "/etc/grc.conf"
    safe_copy "${CWD}/configs/grc/grc.zsh" "/etc/grc.zsh"
}
################################################################################
configure_vim() {
    display_success "Configuring VIM"
    safe_copy "${CWD}/configs/vim/.vimrc" "${HOME}/.vimrc"
    safe_copy "${CWD}/configs/vim/monokai.vim" "${HOME}/.vim/colors/monokai.vim"
    # Install All Plugins
    vim +PluginInstall +qall && cp "${HOME}/.vim/bundle/vim-monokai/colors/monokai.vim" "${HOME}/.vim/colors/monokai.vim"
}
################################################################################
install_cheatsheet() {
    curl https://cht.sh/:cht.sh > "${HOME}/bin/cht.sh"
    sudo chmod +x "${HOME}/bin/cht.sh"
}
################################################################################
install_apt_package() {
        display_success "Installing Package: ${CWHITE}$1"
        sudo apt-get install -y $1
}
################################################################################
install_oh_my_zsh() {
    if [[ -e "${HOME}/.oh-my-zsh/oh-my-zsh.sh" ]]; then
        display_warning "Skipping Installation Oh-My-ZSH (Already Installed)"
    else
        display_success "Installing: ${CWHITE}Oh-My-ZSH"
        # sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
        ${CWD}/oh-my-zsh/tools/install.sh
        display_message "Changing default shell to ZSH"
        chsh -s /usr/bin/zsh
    fi
}
################################################################################
install_spaceship_theme() {
    if [[ -e "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt" ]]; then
        display_warning "Skipping Installation: Spaceship (Already Installed)"
    else
        display_success "[+] Installing ZSH Theme:${CWHITE} Spaceship Prompt"
        copy_recursive "${CWD}/spaceship-prompt" "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt"
        ln -s "${HOME}/.oh-my-zsh/custom/themes/spaceship-prompt/spaceship.zsh-theme" "${HOME}/.oh-my-zsh/themes/spaceship.zsh-theme"
    fi
}
################################################################################
install_vundle() {
    if [[ -e "${HOME}/.vim/bundle/Vundle.vim" ]]; then
        display_warning "Skipping Installation Vundle (Already Installed)"
    else
        display_success "Installing VIM Package: ${CWHITE}Vundle"
        git clone "https://github.com/VundleVim/Vundle.vim.git" ~/.vim/bundle/Vundle.vim
    fi
}
################################################################################
reset_home_dir_permissions() {
    sudo chown ${TUSR}:${TUSR} -R $HOME
}
################################################################################
add_terminal_colors() {
    # Reset Color
    CE="\033[0m"
    # Text: Common Color Names
    CT="\033[38;5;"
    CRED="${CT}9m"
    CGREEN="${CT}28m"
    CBLUE="${CT}27m"
    CORANGE="${CT}202m"
    CYELLOW="${CT}226m"
    CPURPLE="${CT}53m"
    CWHITE="${CT}255m"
    # Text: All Hex Values
    for HEX in {0..255};do eval "C$HEX"="\\\033[38\;5\;${HEX}m";done
    # Background: Common Color Names
    CB="\033[48;5;"
    CBRED="${CB}9m"
    CBGREEN="${CB}46m"
    CBBLUE="${CB}27m"
    CBORANGE="${CB}202m"
    CBYELLOW="${CB}226m"
    CBPURPLE="${CB}53m"
    # Background: All Hex Values
    for HEX in {0..255};do eval "CB${HEX}"="\\\033[48\;5\;${HEX}m";done
}
add_terminal_colors
main "$@"
