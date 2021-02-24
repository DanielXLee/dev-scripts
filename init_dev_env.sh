#!/bin/bash

# Step 1: Install zsh and git if not exist
# yum install zsh git -y

# Step 2: Install oh-my-zsh
sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"

# Step 3: Install zsh plugin
git clone https://github.com/zsh-users/zsh-autosuggestions ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-autosuggestions
git clone https://github.com/zdharma/history-search-multi-word.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/history-search-multi-word
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git ${ZSH_CUSTOM:-~/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting 
sed -i 's/^plugins=.*/plugins=(git z kubectl zsh-autosuggestions history-search-multi-word zsh-syntax-highlighting)/g' ~/.zshrc
sed -i 's/^ZSH_THEME=.*/ZSH_THEME=cloud/g' ~/.zshrc
source ~/.zshrc

# Step 4: Install latest golang
wget -q -O - https://git.io/vQhTU | bash -s -- --version 1.16
