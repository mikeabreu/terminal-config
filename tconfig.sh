#!/bin/bash
#
#   File: tconfig.sh
#   Author: Mike Abreu
#
#   Usage: tconfig.sh command [options]
#
#   Example:
#       # Install terminal configurations
#       ./tconfig.sh install [-s][--silent] [--no-grc] [--theme=THEME_NAME]
#
#       # Update terminal configuration dependencies
#       ./tconfig.sh update
#
#       # Change Oh-My-ZSH Themes
#       ./tconfig.sh theme [THEME_NAME] [-l][--list]
#
#   This script was built to help automate the process of customizing a users
#   terminal. The target configuration to run this script in is a fresh install.
#   The script is safe to your existing configurations and copies them to the
#   same file name and location with .bkp appended. Example: ~/.zshrc.bkp
#
################################################################################
main() {
    # Check if no arguments were passed.
    if [[ $# -lt 1 ]]; then
        display_help
        exit 0
    fi

    # Set variables
    CWD=$(dirname $0)
    font=true
    vim=true
    theme="fino"

    handle_install_arguments $@

    display_success "Updating git submodules"
    git submodule update --init

    # fix_zsh_install
    sed -i 's/env zsh//g' oh-my-zsh/tools/install.sh

    # Create all required file locations
    create_directory "${HOME}/.grc"
    create_directory "${HOME}/.config/terminator/"
    if $vim; then
        create_directory "${HOME}/.vim/bundle"
        create_directory "${HOME}/.vim/colors"
    fi

    # Display information
    display_success "Terminal Configuration Started"

    # STEP 1: Install ZSH, GRC, VIM and TERMINATOR
    apt-get update
    install_apt_package "terminator"
    install_apt_package "zsh"
    install_apt_package "bc"
    if $vim; then install_apt_package "vim"; fi
    if $vim; then install_apt_package "grc"; fi
    if $font; then install_apt_package "python-fontforge"; fi

    # STEP 2: Install Oh-My-ZSH
    install_oh_my_zsh

    # STEP 3: Configure Theme for ZSH
    display_success "Configuring: ${CWHITE}Oh-My-ZSH"
    if [[ $theme == 'powerlevel9k' ]]; then
        install_powerlevel9k_theme
        configure_powerlevel9k_theme
    else
        configure_fino_theme
    fi

    # STEP 4: Configure GRC
    if $grc; then configure_grc; fi

    # STEP 5: Install Vundle
    if $vim; then install_vundle; fi

    # STEP 6: Configure VIM
    if $vim; then configure_vim; fi

    # STEP 7: Configure Terminator
    configure_terminator

    # STEP 8: Install Awesome Terminal Fonts
    if $font; then install_awesome_fonts; fi

    # STEP 9: Tell user to restart the terminal
    display_warning "Please open terminator."
    display_success "Terminal Configuration Finished"
    env zsh
}
################################################################################
#   FUNCTIONS
################################################################################
display_help() {
    echo -e """${CORANGE}
    Terminal Customization Script

    Usage:${CE}${CBLUE} customize-terminal.sh start [options]${CORANGE}

    This script was built to help automate the process of customizing a users
    terminal. The target configuration to run this script in is a fresh install.
    The script is safe to your existing configurations and copies them to the
    same file name and location with .bkp appended. Example: ~/.zshrc.bkp

    Options:
    Full Word        |   Single Letter |    Description${CE}
    --theme <THEME>  |   -t <THEME>    |    Selects the Oh-My-ZSH Theme. Default is bira.
                                            Themes are 'bira' or 'powerlevel9k'.
    --no-vim         |                 |    Tells the installer to not add VIM configurations.
    --no-font        |                 |    Tells the installer to not install Awesome Terminal Fonts.
    --no-grc         |                 |    Tells the installer to not install GRC.
    ${CORANGE}
    Example:${CE}
        ${CBLUE}tconfig.sh start --no-vim --theme=powerlevel9k${CE}
    """
    exit 0
}
################################################################################
handle_install_arguments() {
    TEMP=`getopt -o t:h -l help,theme:,no-vim,no-font,no-grc -- "$@"`
    if [[ $? != 0 ]]; then echo "Terminating." >&2 ; exit 1; fi
    eval set -- "$TEMP"
    while true; do
        case "$1" in
            -h | --help) display_help; shift ;;
            -t | --theme) set_theme $2; shift 2 ;;
            --no-vim) display_info "Argument Accepted: ${CWHITE}Skipping VIM Configuration."
                    vim=false; shift ;;
            --no-font) display_info "Argument Accepted: ${CWHITE}Skipping Font Configuration."
                font=false; shift ;;
            --no-grc) display_info "Argument Accepted: ${CWHITE}Skipping GRC Configuration."
                grc=false; shift ;;
            -- ) shift; break ;;
            *) break ;;
        esac
    done
}
################################################################################
set_theme() {
    if [[ $(echo $1 |grep -oE '^[bB][iI][rR][aA]$') ]]; then
        display_info "Argument Accepted: ZSH: Bira Theme Enabled."
        theme='bira'
    elif [[ "$(echo $1 |grep -oE '^[fF][iI][nN][oO]$')" ]]; then
        display_info "Argument Accepted: ZSH: Fino Theme Enabled."
        theme='fino'
    elif [[ "$(echo $1 |grep -oE '^[pP][oO][wW][eE][rR][lL][eE][vV][eE][lL][9][kK]$')" ]]; then
        display_info "Argument Accepted: ZSH: Powerlevel9K Theme Enabled."
        theme='powerlevel9k'
    else
        display_error "Invalid theme. Defaulting to fino."
        theme='fino'
    fi
}
################################################################################
display_info() {
    display_bar $CBLUE
    echo -e "${CBLUE}[*]${CE} ${1}${CE}"
    display_bar $CBLUE
}
display_message() {
    echo -e "${CGREEN}[+]${CE} ${1}${CE}"
}
display_success() {
    display_bar $CGREEN
    echo -e "${CGREEN}[+]${CE} ${1}${CE}"
    display_bar $CGREEN
}
display_warning() {
    display_bar $CYELLOW
    echo -e "${CYELLOW}[!]${CE} ${1}${CE}"
    display_bar $CYELLOW
}
display_error() {
    display_bar $CRED
    echo -e "${CRED}[-]${CE} ${1}${CE}"
    display_bar $CRED
}
display_bar() {
    echo -e "${1}====================================================================================================${CE}"
    #echo -e "${1}----------------------------------------------------------------------------------------------------${CE}"
    #echo -e "${1}####################################################################################################${CE}"
}
################################################################################
install_apt_package() {
        display_success "Installing Package: ${CWHITE}$1"
        sudo apt-get install -y $1
}
################################################################################
create_directory() {
    if [[ ! -e $1 ]]; then
        display_message "Creating Directory:${CWHITE} $1"
        mkdir -p $1
    fi
}
################################################################################
safe_copy() {
    if [[ -e $2 ]]; then
        safe_backup $2
    fi
    display_message "File Copy:${CBLUE} ${1} ${CE}copied to${CGREEN} ${2}"
    cp "${1}" "${2}"
}
################################################################################
safe_backup() {
    if [[ -e $1 ]]; then
        display_message "File Backup:${CBLUE} ${1} ${CE}copied to${CGREEN} ${1}.bkp"
        cp "${1}" "${1}.bkp"
    fi
}
################################################################################
install_oh_my_zsh() {
    if [[ -e "${HOME}/.oh-my-zsh/oh-my-zsh.sh" ]]; then
        display_warning "Skipping Installation Oh-My-ZSH (Already Installed)"
    else
        display_success "Installing: ${CWHITE}Oh-My-ZSH"
        # sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
        ${CWD}/oh-my-zsh/tools/install.sh
        chsh -s /usr/bin/zsh
    fi
}
################################################################################
install_powerlevel9k_theme() {
    if [[ -e "${HOME}/.oh-my-zsh/custom/themes/powerlevel9k" ]]; then
        display_warning "Skipping Installation: Powerlevel9k (Already Installed)"
    else
        display_success "[+] Installing ZSH Theme:${CWHITE} Powerlevel9k"
        git clone "https://github.com/bhilburn/powerlevel9k.git" "${HOME}/.oh-my-zsh/custom/themes/powerlevel9k"
    fi
}
################################################################################
configure_powerlevel9k_theme() {
    safe_copy "${CWD}/configs/zsh/.zshrc_powerlevel9k" "${HOME}/.zshrc"
}
configure_bira_theme() {
    safe_copy "${CWD}/configs/zsh/.zshrc_bira" "${HOME}/.zshrc"
}
configure_fino_theme() {
    safe_copy "${CWD}/configs/zsh/.zshrc_fino" "${HOME}/.zshrc"
}
################################################################################
configure_grc() {
    display_success "Configuring GRC"
    safe_copy "${CWD}/configs/grc/conf.nmap" "${HOME}/.grc/conf.nmap"
    safe_copy "${CWD}/configs/grc/grc.conf" "/etc/grc.conf"
    safe_copy "${CWD}/configs/grc/grc.zsh" "/etc/grc.zsh"
    safe_copy "${CWD}/configs/grc/conf.ls" "/usr/share/grc/conf.ls"
}
################################################################################
install_vundle() {
    if [[ -e "${HOME}/.vim/bundle/Vundle.vim" ]]; then
        display_warning "Skipping Installation Vundle (Already Installed)"
    else
        display_success "Installing VIM Package: ${CWHITE}Vundle"
        git clone "https://github.com/VundleVim/Vundle.vim.git" "${HOME}/.vim/bundle/Vundle.vim"
    fi
}
################################################################################
configure_vim() {
    display_success "Configuring VIM"
    safe_copy "${CWD}/configs/vim/.vimrc" "${HOME}/.vimrc"
    safe_copy "${CWD}/configs/vim/monokai.vim" "${HOME}/.vim/colors/monokai.vim"
    # Install All Plugins
    vim +PluginInstall +qall && cp "${HOME}/.vim/bundle/vim-monokai/colors/monokai.vim ${HOME}/.vim/colors/monokai.vim"
}
################################################################################
configure_terminator() {
    display_success "Configuring Terminator"
    safe_copy "${CWD}/configs/terminator/config" "${HOME}/.config/terminator/config"
}
################################################################################
install_awesome_fonts() {
    if [ -e "${HOME}/.fonts/SourceCodePro+Powerline+Awesome+Regular.ttf" ]; then
        display_warning "Skipping Installation Awesome Terminal Fonts (Already Installed)"
    else
        display_success "Installing: ${CWHITE}Awesome Terminal Fonts"
        safe_backup "${HOME}/.fonts"
        mkdir -p "${HOME}/.fonts"               # Create the fonts dir required
        cd "${CWD}/awesome-terminal-fonts" && "./sourcecodepro.sh" 1>&2 /dev/null
        cd "${CWD}"
    fi
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
    CBGREEN="${CB}28m"
    CBBLUE="${CB}27m"
    CBORANGE="${CB}202m"
    CBYELLOW="${CB}226m"
    CBPURPLE="${CB}53m"
    # Background: All Hex Values
    for HEX in {0..255};do eval "CB${HEX}"="\\\033[48\;5\;${HEX}m";done
}
add_terminal_colors
main "$@"
