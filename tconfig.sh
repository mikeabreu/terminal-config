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
    clear
    # Display confirmation
    display_script_confirmation

    # Set variables
    CWD=$(dirname $0)
    font=true
    vim=true

    # Display information
    display_theme_selection

    display_success "Updating git submodules"
    git submodule update --init

    # remove 'env zsh' line in install.sh script for oh-my-zsh
    sed -i 's/env zsh//g' oh-my-zsh/tools/install.sh

    # Create all required file locations
    create_directory "${HOME}/.grc"
    create_directory "${HOME}/.config/terminator/"
    if $vim; then
        create_directory "${HOME}/.vim/bundle"
        create_directory "${HOME}/.vim/colors"
    fi

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
    case $theme in
        [pP][oO][wW][eE][rR][lL][eE][vV][eE][lL][9][kK])
            install_powerlevel9k_theme
            configure_powerlevel9k_theme
            ;;
        [bB][iI][rR][aA])
            configure_bira_theme
            ;;
        [fF][iI][nN][oO])
            configure_fino_theme
            ;;
        *)
            display_error "Invalid Oh-My-ZSH theme was selected. Exiting script."
            exit 1
            ;;
    esac

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
display_theme_selection() {
    invalid_theme_selected=true
    echo
    display_bar $CYELLOW
    echo -e "${CYELLOW}[!]${CE} Please select an Oh-My-ZSH theme from the list below.${CE}"
    echo
    echo -e "    ${CWHITE}powerlevel9k${CE}"
    echo -e "    ${CWHITE}bira${CE}"
    echo -e "    ${CWHITE}fino${CE}"
    display_bar $CYELLOW
    while $invalid_theme_selected; do
        echo
        echo -en "${CYELLOW}[!]${CE} Enter the Oh-My-ZSH theme you wish to use: ${CE}"
        read -r response
        case $response in
            [pP][oO][wW][eE][rR][lL][eE][vV][eE][lL][9][kK])
                set_theme "powerlevel9k"
                invalid_theme_selected=false
                ;;
            [bB][iI][rR][aA])
                set_theme "bira"
                invalid_theme_selected=false
                ;;
            [fF][iI][nN][oO])
                set_theme "fino"
                invalid_theme_selected=false
                ;;
            *)
                display_error "Invalid Oh-My-ZSH theme was selected. Try again."
                ;;
        esac
    done
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
install_vundle() {
    if [[ -e "${HOME}/.vim/bundle/Vundle.vim" ]]; then
        display_warning "Skipping Installation Vundle (Already Installed)"
    else
        display_success "Installing VIM Package: ${CWHITE}Vundle"
        git clone "https://github.com/VundleVim/Vundle.vim.git" "${HOME}/.vim/bundle/Vundle.vim"
    fi
}
################################################################################
set_theme() {
    case $1 in
        [pP][oO][wW][eE][rR][lL][eE][vV][eE][lL][9][kK])
            display_info "Oh-My-ZSH Theme Accepted: ${CWHITE}Powerlevel9K"
            theme='powerlevel9k'
            ;;
        [bB][iI][rR][aA])
            display_info "Oh-My-ZSH Theme Accepted: ${CWHITE}Bira"
            theme='bira'
            ;;
        [fF][iI][nN][oO])
            display_info "Oh-My-ZSH Theme Accepted: ${CWHITE}Fino"
            theme='fino'
            ;;
        *)
            false
            ;;
    esac
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
