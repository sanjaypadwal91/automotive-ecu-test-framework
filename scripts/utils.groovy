def getGitBranch() {
    return env.GIT_BRANCH
}

def printMessage(msg) {
    echo "INFO: ${msg}"
}