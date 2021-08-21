# deleto-dorito
Smartparens addon for deletion commands (mostly)

I noticed that a lot of delete commands were leaving the yank system dirty, especially since they're put in terms of their respective kill-commands, shadowing the kill-ring but not covering kill-ring-yank-pointer.

I wasn't sure if it was worth the effort to try and fix the hack with more hacks, and honestly i just wanted feature additions, so i just made an addon instead.

load after smartparens

research:
Github issue:
https://github.com/Fuco1/smartparens/issues/1097

SO (see comments and answers not just the top answer):
https://stackoverflow.com/questions/13141292/how-to-remove-the-top-entry-pop-from-the-emacs-kill-ring
