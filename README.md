# toter
Simple, secure dotfiles management for Linux and Mac.

git, bash, gpg

- stuff here
- use Toter to quickly personalize a dev container
- 

When storing encrypted secrets in your dotfiles git repo, we recommend using keeping them in a private repo.

AES-256 cipher, but it is only as secure as your passphrase. Please take precautions select a strong passphrase and protect the systems where you use/store it.


You'll most likely be cloning your dotfiles from a remote private repository. GitHub has removed password authentication for private repos (https://docs.github.com/en/get-started/getting-started-with-git/about-remote-repositories) so you'll need to use personal access tokens (https://docs.github.com/en/get-started/getting-started-with-git/about-remote-repositories) or the GitHub CLI.
