# Vagrant Arch Linux build scripts for vmware_fusion boxes on osx (maybe more later)

So here are my opinionated vagrant box build scripts for arch linux for vmware fusion.

In short, basically you use the current (as of writing) 2013-03-01 iso image, boot it in vmware then curl -L the script, or get it to the system any way you can.

Then pipe it to sh -x or whatever and it will do the rest.

# My opinionated way of doing things/setting up arch.

So what you get is this:

* sda1 /boot  100m ext2
* sda2 /      rest ext4

No swap (why bother, do that in post with a file if you need it), and given these boxes purpose no real need.

An ``/etc/hostname`` of *changeme*. No root password (set that up in your provisioner of choice). Vagrant user setup to use the public vagrant key, and some other nonimportant things.

I loathe using systemd, but since its the "new hotness(sic)" I setup a legacy systemd rc.local service and use that for bootstrapping things.

I then setup open-vm-tools for hgfs/etc...

And finally I install ruby and then have gem install to the system ruby puppet/chef because why not, note I hate the default ``/etc/gemrc`` arch uses.

It isn't perfect, and things like bridged networks don't seem to work properly due to the new naming scheme for networks as vagrant expects old ethN not the new schema devices. But for my limited needs this works.

Note I haven't yet tested chef/puppet provisioners, just the shell provisioner.

But this seems to do the trick for local dev. Patches/insults/comments welcome.

# After your new hotness arch linux vmware vm is built

I also scripted the box creation out of laziness.

Example box build, note the script copies the files to TEMPDIR (or /tmp if undefined) and works on them there so as not to effect the original vm's.

<pre>$ arch-build-box-vmware_fusion.sh ~/Documents/Virtual\ Machines.localized/arch64.vmwarevm ~/test.box
temp dir is: /var/folders/sm/y5r6pb0902jg359dkrqldjhw0000gn/T//32165
Specify a filename for the boxfile to output to.
Copying vmware files to /var/folders/sm/y5r6pb0902jg359dkrqldjhw0000gn/T//32165 from /Users/mitch/Documents/Virtual Machines.localized/arch64.vmwarevm.
Defragmenting vmdk's
  Defragment: 100% done.
Defragmentation completed successfully.
Shrinking vmdk's
  Shrink: 100% done.
Shrink completed successfully.
Building boxfile /Users/mitch/test.box
Cleaning up after myself.
done</pre>

# TODO: ?

Well improve the scripts to be able to build virtualbox too might be useful.

But bigger than that I think the most useful thing would be to automate the actual vm creation in vmware fusion with say applescript. Haven't looked into this much at all as I loath applescript and gui automation. But until now its not overly difficult to do this manually.

Thats about all I can think of for the moment.
