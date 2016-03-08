# .bashrc

# Source global definitions
if [ -f /etc/bashrc ]; then
    . /etc/bashrc
fi

source ~/git-completion.bash

# User specific aliases and functions
alias r="screen -r"
alias gr="git log --graph --full-history --all --color --pretty=tformat:\"%x1b[31m%h%x09%x1b[32m%d%x1b[0m%x20%s%x20%x1b[33m(%an)%x1b[0m;\""
alias grd="git log --graph --full-history --all --color --pretty=tformat:\"%x1b[31m%h%x09%x1b[36m%ad%x1b[32m%d%x1b[0m%x20%s%x20%x1b[33m(%an)%x1b[0m;\" --date=iso"
alias st="git status"
alias ci="git commit"
alias ud="git add -u; d"
alias cim="git commit -m"
gitCPNC(){
    hashkey=$1
    message=$2
    git cherry-pick -n $hashkey
    git commit -m "$2"
}
alias gcpnc=gitCPNC
gitCPN(){
    hashkey=$1
    git cherry-pick -n $hashkey
}
alias gcpn=gitCPN
gitDiffHead(){
    # --no-prefix 
    git diff HEAD -C "$@" > diff.diff
    git diff --stat HEAD
}
alias d=gitDiffHead
alias dh=gitDiffHead
gitDiffCurrent() {
    git diff "$@" > diff.diff
    git diff --stat
}
alias dc=gitDiffCurrent
gitDiffStaged() {
    git diff --staged "$@" > diff.diff
    git diff --staged --stat
}
alias ds=gitDiffStaged
alias a="git add"
# alias c="vim _commit-message.commit-message;git commit -F _commit-message.commit-message; rm _commit-message.commit-message"
alias bcc="bash cache-clear.sh"
alias cc="bash cache-clear.sh"
alias sfs="php symfony --shell"

# projects
alias cdevo="cd ~/www/evolution"

# gulp
alias gw="gulp watch & "

# rmhist <from> <to>
rmhist() {
    start=$1
    end=$2
    count=$(( end - start ))
    while [ $count -ge 0 ] ; do
        history -d $start
        ((count--))
    done
}
unchanger(){
    oldname=$1
    newname=$2
    git checkout HEAD -- $oldname
    git rm -f $newname
    git mv $oldname $newname
    git diff -C -D --staged > diff.diff
}
# SVN
alias svnsti="svn st --ignore-externals"
alias svnst="svn st"
alias svnadd="svn changelist TO-COMMIT"
alias svnci="svn commit --changelist TO-COMMIT"

