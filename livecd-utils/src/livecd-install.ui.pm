#############################################################################
# ui.pm extension file, included from the puic-generated form implementation.
# If you wish to add, delete or rename signals or slots use
# the Perl-enabled Qt Designer which will update this file,
# preserving your code.
#
# 'SLOT:' markers are not meant to be created or edited manually.
# Please use the Slots dialog and/or the Object Browser.
#############################################################################

use threads;

use lib qw(/usr/lib/libDrakX);

use common;
use fs;
use swap;

my $destroy = 0;
my $isBusy  = 0;
my $reboot  = undef;

my $prefix = "/tmp";
my $mnt    = "/tmp/livecd.install.$$";
my $log    = "/tmp/livecd.install.log.$$";
my $initrd = "/initrd/loopfs";
my %devs   = ();

my $eventloop = undef;

my $rootpart = undef;
my $swappart = undef;
my $homepart = undef;
my $varpart  = undef;
my $tmppart  = undef;
my $bootdev  = undef;

my %fsnames = (
    'swap'     => 'Linux swap',
    'ext2'     => 'Linux native',
    'reiserfs' => 'Journalised FS: ReiserFS',
    'xfs'      => 'Journalised FS: XFS',
    'jfs'      => 'Journalised FS: JFS',
    'ext3'     => 'Journalised FS: ext3'
);

my %fsopts = (
    'ext2'     => 'defaults',
    'ext3'     => 'defaults',
    'jfs'      => 'defaults',
    'reiserfs' => 'notail,noatime',
    'xfs'      => 'defaults'
);


sub pageSelected # SLOT: ( const QString & )
{
    my ($title) = @_;

    my $page = this->currentPage();
    this->setHelpEnabled($page, 0);
    #this->setCancelEnabled($page, 0);
    doEvents();

    if ($title =~ m/ 1/) {
	this->setFinishEnabled($page, 0);
	doEvents();
    }
    elsif ($title =~ m/ 2/) {
	this->setBackEnabled($page, 0);
	this->setNextEnabled($page, 0);
	doEvents();
	#threads->new(\&scanPartitions, this, $page, \%devs);
	scanPartitions(this, $page, \%devs);
	foreach my $dev (sort keys %devs) {
	    print "$dev, ".$devs{$dev}{media}.", ".$devs{$dev}{type}."\n";
	}
    }
    elsif ($title =~ m/ 3/) {
	showVerify(this, $page, \%devs);
    }
    elsif ($title =~ m/ 4/) {
	this->setBackEnabled($page, 0);
	this->setNextEnabled($page, 0);
	doEvents();
	threads->new(\&showInstall, this, $page, \%devs);
    }
    elsif ($title =~ m/ 5/) {
	showBootloader(this, $page, \%devs);
    }
    elsif ($title =~ m/ 6/) {
	this->setBackEnabled($page, 0);
	this->setNextEnabled($page, 0);
	this->setFinishEnabled($page, 1);
	doEvents();
	$reboot = 1;
    }
}


sub init
{
    #select(STDERR);
    #$| = 1;
    #open STDERR, '>', "$log";
    #threads->new(\&logThread, this, $log);
    select(STDOUT);
    $| = 1;
    print "Initialising ... ";
    system("mkdir -p $mnt");
    print "Done.\n";
}


sub destroy
{
    print "Destroying ... ";

    # notify threads that we are to die and keep
    # looping until we don't have a thread anymore
    $destroy = 1;
    sleep(1) while ($isBusy);

    system("umount $mnt/home") if (defined($homepart));
    system("umount $mnt/var") if (defined($varpart));
    system("umount $mnt/tmp") if (defined($tmppart));
    system("umount $mnt && rm -rf $mnt");

    #close(STDERR);
    system("rm -rf $log");

    print "Done.\n";
    if (defined($reboot)) {
	print "Rebooting...\n";
	exec("/sbin/reboot");
    }
}


sub setBusy
{
    my ($busy) = @_;
    $isBusy = $busy;
}


sub scanPartitions
{
    my ($this, $page, $devs) = @_;

    $this->setBackEnabled($page, 0);
    $this->setNextEnabled($page, 0);

    if ($this->cbRoot->count() eq 0) {
	$this->cbRoot->insertItem("(none)");
	$this->cbRoot->setCurrentItem(0);
	$this->cbSwap->insertItem("(none)");
	$this->cbSwap->setCurrentItem(0);
	$this->cbHome->insertItem("(none)");
	$this->cbHome->setCurrentItem(0);
	$this->cbVar->insertItem("(none)");
	$this->cbVar->setCurrentItem(0);
	$this->cbTmp->insertItem("(none)");
	$this->cbTmp->setCurrentItem(0);

	system("mkdir -p $prefix/etc/livecd/hwdetect");
	system("/initrd/usr/sbin/hwdetect --prefix $prefix --fdisk >/dev/null");
	foreach my $line (common::cat_("$prefix/etc/livecd/hwdetect/mounts.cfg")) {
	    chomp($line);
	    my ($dev, $info) = split(/=\|/, $line, 2);
	    my $devlnk = "/dev/$dev";
	    %{$devs->{$devlnk}} = map {
		chomp;
		my ($name, $value) = split(/=/, $_, 2);
		print "$dev: $name = [ $value ]\n";
		$name => $value || 1;
	    } split(/\|/, $info);
	}

	foreach (sort keys %$devs) {
	    if ($devs->{$_}{type} =~ /ext2/ ||
		$devs->{$_}{type} =~ /ext3/ ||
		$devs->{$_}{type} =~ /reiserfs/ ||
		$devs->{$_}{type} =~ /xfs/ ||
		$devs->{$_}{type} =~ /jfs/ ||
		$devs->{$_}{type} =~ /swap/) {
		my $size = int((512*$devs->{$_}{size})/(1024*1024))."MB";
		my $type = $fsnames{$devs->{$_}{type}};
		if ($devs->{$_}{type} =~ /swap/) {
		    $this->cbSwap->insertItem("$_, $size, $type");
		    $this->cbSwap->setCurrentItem(1);
		}
		else {
		    $this->cbRoot->insertItem("$_, $size, $type");
		    $this->cbHome->insertItem("$_, $size, $type");
		    $this->cbVar->insertItem("$_, $size, $type");
		    $this->cbTmp->insertItem("$_, $size, $type");
		    $this->cbRoot->setCurrentItem(1);
		}
	    }
	}
    }

    $this->setBackEnabled($page, 1);
    $this->setNextEnabled($page, 1);
}



sub showVerify
{
    my ($this, $page, $devs) = @_;

    if ($this->cbRoot->currentText() =~ m/none/) {
	emit back();
	Qt::MessageBox::warning(undef, "Missing root", "You have to specify a root (/) partition", "Retry");
    }
    elsif ($this->cbSwap->currentText() =~ m/none/) {
	emit back();
	Qt::MessageBox::warning(undef, "Missing swap", "You have to specify a swap partition", "Retry");
    }
    elsif (!($this->cbHome->currentText() =~ m/none/) &&
           ($this->cbHome->currentText() eq $this->cbRoot->currentText())) {
	emit back();
	Qt::MessageBox::warning(undef, "Overlapping home", "The home (/home) partition is the same as the root (/) partition.", "Retry");
    }
    elsif (!($this->cbVar->currentText() =~ m/none/) &&
           ($this->cbVar->currentText() eq $this->cbRoot->currentText())) {
	emit back();
	Qt::MessageBox::warning(undef, "Overlapping var", "The var (/var) partition is the same as the root (/) partition.", "Retry");
    }
    elsif (!($this->cbVar->currentText() =~ m/none/) &&
           ($this->cbVar->currentText() eq $this->cbHome->currentText())) {
	emit back();
	Qt::MessageBox::warning(undef, "Overlapping var/home", "The var (/var) partition is the same as the home (/home) partition.", "Retry");
    }
    elsif (!($this->cbTmp->currentText() =~ m/none/) &&
           ($this->cbTmp->currentText() eq $this->cbRoot->currentText())) {
	emit back();
	Qt::MessageBox::warning(undef, "Overlapping temp", "The temp (/tmp) partition is the same as the root (/) partition.", "Retry");
    }
    elsif (!($this->cbTmp->currentText() =~ m/none/) &&
           ($this->cbTmp->currentText() eq $this->cbHome->currentText())) {
	emit back();
	Qt::MessageBox::warning(undef, "Overlapping temp", "The temp (/tmp) partition is the same as the home (/home) partition.", "Retry");
    }
    elsif (!($this->cbTmp->currentText() =~ m/none/) &&
           ($this->cbTmp->currentText() eq $this->cbVar->currentText())) {
	emit back();
	Qt::MessageBox::warning(undef, "Overlapping temp/var", "The temp (/tmp) partition is the same as the var (/var) partition.", "Retry");
    }
    else {
	$this->lvVerify->clear();
	my $item = undef;
	my $text = undef;
	my @rest = undef;

	$item = Qt::ListViewItem($this->lvVerify, $item);
	$text = $this->cbSwap->currentText();
	($swappart, @rest) = split(/,/, $text);
	$item->setText(0, "(swap)");
	$item->setText(1, $text);
	$item->setText(2, "Yes") if ($this->cbSwapFormat->isChecked());
	unless ($this->cbTmp->currentText() =~ m/none/) {
	    $item = Qt::ListViewItem($this->lvVerify, $item);
	    $text = $this->cbTmp->currentText();
	    ($tmppart, @rest) = split(/,/, $text);
	    $item->setText(0, "/tmp");
	    $item->setText(1, $text);
	    $item->setText(2, "Yes") if ($this->cbTmpFormat->isChecked());
	}
	unless ($this->cbVar->currentText() =~ m/none/) {
	    $item = Qt::ListViewItem($this->lvVerify, $item);
	    $text = $this->cbVar->currentText();
	    ($varpart, @rest) = split(/,/, $text);
	    $item->setText(0, "/var");
	    $item->setText(1, $text);
	    $item->setText(2, "Yes") if ($this->cbVarFormat->isChecked());
	}
	unless ($this->cbHome->currentText() =~ m/none/) {
	    $item = Qt::ListViewItem($this->lvVerify, $item);
	    $text = $this->cbHome->currentText();
	    ($homepart, @rest) = split(/,/, $text);
	    $item->setText(0, "/home");
	    $item->setText(1, $text);
	    $item->setText(2, "Yes") if ($this->cbHomeFormat->isChecked());
	}
	$item = Qt::ListViewItem($this->lvVerify, $item);
	$text = $this->cbRoot->currentText();
	($rootpart, @rest) = split(/,/, $text);
	$item->setText(0, "/");
	$item->setText(1, $text);
	$item->setText(2, "Yes") if ($this->cbRootFormat->isChecked());
    }
}


sub showInstall
{
    my ($this, $page, $devs) = @_;

    $this->setBusy(1);

    $this->setBackEnabled($page, 0) unless ($destroy);
    $this->setNextEnabled($page, 0) unless ($destroy);
    $this->tlInstInfo->setText("Scanning available directories") unless ($destroy);

    my $fmtsteps = 0;
    $fmtsteps++ if ($this->cbRootFormat->isChecked());
    $fmtsteps++ if ($this->cbSwapFormat->isChecked());
    $fmtsteps++ if (defined($homepart) && ($this->cbHomeFormat->isChecked()));
    $fmtsteps++ if (defined($varpart) && ($this->cbVarFormat->isChecked()));
    $fmtsteps++ if (defined($tmppart) && ($this->cbTmpFormat->isChecked()));
    if ($fmtsteps) {
	$this->pbFormat->setProgress(0, $fmtsteps) unless ($destroy);
	$this->pbOverall->setProgress(0, $fmtsteps) unless ($destroy);
    }
    else {
	$this->pbFormat->setProgress(0, 1) unless ($destroy);
	$this->pbFormat->setProgress(1) unless ($destroy);
	$this->pbOverall->setProgress(0, 1) unless ($destroy);
    }
    threads->new(\&timeThread, $this, $page, time, $this->pbOverall, $this->tlOverall) unless ($destroy);

    my @dirs = qx(find $initrd/ -type d | sed -s 's,$initrd,,' | grep -v ^/proc | grep -v ^/dev | grep -v ^/home | grep -v ^/root | grep -v ^/etc);
    print "scalar(dirs)=".scalar(@dirs)."\n";
    my $copysteps = scalar(@dirs);

    my @etcdirs = qx(find /etc -type d);
    print "scalar(etcdirs)=".scalar(@etcdirs)."\n";
    $copysteps = $copysteps + scalar(@etcdirs);

    my @homedirs = qx(find /home -type d);
    print "scalar(homedirs)=".scalar(@homedirs)."\n";
    $copysteps = $copysteps + scalar(@homedirs);

    my @rootdirs = qx(find /root -type d);
    print "scalar(rootdirs)=".scalar(@rootdirs)."\n";
    $copysteps = $copysteps + scalar(@rootdirs);

    $this->pbCopy->setProgress(0, $copysteps);

    my $totsteps = $copysteps+$fmtsteps;
    $this->pbOverall->setProgress(0, $totsteps);
    print "pbOverall->setProgress(0, $totsteps);\n";

    if ($fmtsteps) {
	threads->new(\&timeThread, $this, $page, time, $this->pbFormat, $this->tlFormat) unless ($destroy);
	doFormat($this, $devs);
    }

    threads->new(\&timeThread, $this, $page, time, $this->pbCopy, $this->tlCopy) unless ($destroy);
    system("mkdir -p $mnt");
    system("mount -t ".$devs->{$rootpart}{type}." $rootpart $mnt");
    system("mkdir -p $mnt/home ; chmod 755 $mnt/home");
    system("mkdir -p $mnt/tmp ; chmod 777 $mnt/tmp");
    system("mkdir -p $mnt/var ; chmod 755 $mnt/var");
    system("mount -t ".$devs->{$homepart}{type}." $homepart $mnt/home") if (defined($homepart));
    system("mount -t ".$devs->{$varpart}{type}." $varpart $mnt/var") if (defined($varpart));
    system("mount -t ".$devs->{$tmppart}{type}." $tmppart $mnt/tmp") if (defined($tmppart));

    system("mkdir -p $mnt/initrd ; chmod 755 $mnt/initrd");
    system("mkdir -p $mnt/home ; chmod 755 $mnt/home");
    system("mkdir -p $mnt/dev ; chmod 755 $mnt/dev");
    system("mkdir -p $mnt/proc ; chmod 755 $mnt/proc");
    system("mkdir -p $mnt/root/tmp ; chmod -R 755 $mnt/root/tmp");
    system("mkdir -p $mnt/tmp ; chmod 777 $mnt/tmp");
    system("mkdir -p $mnt/var/lock/subsys ; chmod -R 755 $mnt/var/lock/subsys");
    system("mkdir -p $mnt/var/run/netreport ; chmod -R 755 $mnt/var/run/netreport ; touch $mnt/var/run/utmp");
    system("cd $mnt/var ; ln -s ../tmp");

    doCopy($this, $initrd, $devs, @dirs);
    doCopy($this, "/", $devs, @etcdirs);
    doCopy($this, "/", $devs, @homedirs);
    doCopy($this, "/", $devs, @rootdirs);

    $this->tlInstInfo->setText("Creating /etc/fstab") unless ($destroy);
    writeFstab($devs) unless ($destroy);

    $this->pbOverall->setProgress(1, 1) unless ($destroy);
    $this->pbCopy->setProgress(1, 1) unless ($destroy);
    $this->pbFormat->setProgress(1, 1) unless ($destroy);

    $this->tlInstInfo->setText("Installation completed.") unless ($destroy);
    $this->setNextEnabled($page, 1) unless ($destroy);

    $this->setBusy(0);
}


sub timeThread
{
    my ($this, $page, $start, $pb, $tl) = @_;
    while (!$destroy && ($pb->progress() ne $pb->totalSteps())) {
	my $elapsed = time - $start;
	my $elapsed_s = fmtTime($elapsed);
	if ($pb->progress() ne 0) {
	    my $remain_s = fmtTime(($elapsed/$pb->progress())*($pb->totalSteps()-$pb->progress()));
	    $tl->setText("$elapsed_s Elapsed, $remain_s Remaining") unless ($destroy);
	}
	else {
	    $tl->setText("$elapsed_s Elapsed, $elapsed_s Remaining") unless ($destroy);
	}
	sleep(1);
    }

    my $elapsed = time - $start;
    my $elapsed_s = fmtTime($elapsed);
    my $remain_s = fmtTime(($elapsed/$pb->progress())*($pb->totalSteps()-$pb->progress()));
    $tl->setText("$elapsed_s Elapsed, $remain_s Remaining") unless ($destroy);
}


sub fmtTime
{
    my ($t) = @_;
    my $h = int($t/3600);
    my $m = int(($t - $h*3600)/60);
    my $s = int($t - $h*3600 - $m*60);
    sprintf("%02d:%02d:%02d", $h, $m, $s);
}


sub doEvents
{
    eval {
	$eventloop = Qt::Application::eventLoop() unless (defined($eventloop));
	$eventloop->processEvents(3, 1) if ($eventloop->hasPendingEvents());
    }
}


sub doFormat
{
    my ($this, $devs) = @_;

    system("umount $rootpart");
    formatPart($this, $rootpart, $devs) if ($this->cbRootFormat->isChecked());
    if ($this->cbSwapFormat->isChecked()) {
	system("umount $swappart");
	formatPart($this, $swappart, $devs);
    }
    system("umount $homepart") if (defined($homepart));
    formatPart($this, $homepart, $devs) if (defined($homepart) && ($this->cbHomeFormat->isChecked()));
    system("umount $varpart") if (defined($varpart));
    formatPart($this, $varpart, $devs) if (defined($varpart) && ($this->cbVarFormat->isChecked()));
    system("umount $tmppart") if (defined($tmppart));
    formatPart($this, $tmppart, $devs) if (defined($tmppart) && ($this->cbTmpFormat->isChecked()));
}


sub formatPart
{
    my ($this, $dev, $devs) = @_;

    if (!$destroy) {
        print "Formatting:\n$dev (".$fsnames{$devs->{$dev}{type}}.")\n";
	$this->tlInstInfo->setText("Formatting:\n$dev (".$fsnames{$devs->{$dev}{type}}.")") unless ($destroy);

	my @options = ();
	#push @options, "-c";
	if ($devs->{$dev}{type} =~ /ext2/) {
	    push @options, "-m", "0" if ($dev eq $homepart);
	    fs::format_ext2($dev, @options);
	}
	elsif ($devs->{$dev}{type} =~ /ext3/) {
	    push @options, "-m", "0" if ($dev eq $homepart);
	    fs::format_ext3($dev, @options);
	}
	elsif ($devs->{$dev}{type} =~ /jfs/) {
	    fs::format_jfs($dev, @options);
	}
	elsif ($devs->{$dev}{type} =~ /reiserfs/) {
	    fs::format_reiserfs($dev, @options) ;
	}
	elsif ($devs->{$dev}{type} =~ /xfs/) {
	    fs::format_xfs($dev, @options);
	}
	elsif ($devs->{$dev}{type} =~ /swap/) {
	    swap::make($dev, 1);
	}

	$this->pbFormat->setProgress($this->pbFormat->progress()+1) unless ($destroy);
	$this->pbOverall->setProgress($this->pbOverall->progress()+1) unless ($destroy);
    }
}


sub doCopy
{
    my ($this, $from, $devs, @dirs) = @_;

    if (!$destroy) {
	copyDir($this, $from, $_) foreach (@dirs);
    }
}


sub copyDir
{
    my ($this, $from, $dir) = @_;

    chomp($dir);
    if (!$destroy) {
	$this->tlInstInfo->setText("Copying from $from:\n$dir") unless ($destroy);

	system("mkdir -p \"$mnt/$dir\"");
	system("chmod \"--reference=$from/$dir\" $mnt/$dir 2>/dev/null");
	system("chown \"--reference=$from/$dir\" $mnt/$dir 2>/dev/null");
	system("( (cd $from/$dir ; tar --no-recursion --exclude .. -c * .*) | (cd $mnt/$dir ; tar -x) ) 2>/dev/null");

	$this->pbCopy->setProgress($this->pbCopy->progress()+1) unless ($destroy);
	$this->pbOverall->setProgress($this->pbOverall->progress()+1) unless ($destroy);
    }
}


sub showBootloader
{
    my ($this, $page, $devs) = @_;

    $this->setBackEnabled($page, 0);
    $this->lbBootloader->insertItem("$rootpart (Bootsector of partition)");

    my @drives = ();
    foreach my $dev (sort keys %$devs) {
	if ($devs->{$dev}{media} =~ /hd/) {
	    $dev =~ s/[0-9]//;
	    my $found = 0;
	    foreach my $in (@drives) {
		$found = 1 if ($in eq $dev);
	    }
	    push @drives, $dev unless ($found);
	}
    }
    $this->lbBootloader->insertItem("$_ (Master boot record of drive)") foreach (@drives);
    $this->lbBootloader->setCurrentItem(0);
}


sub logThread
{
    my ($this, $log) = @_;
    open LOG, '<', "$log";
    my $line = "";
    while (!$destroy) {
	my $data = <LOG>;
	if (defined($data)) {
	    $data =~ s/010//g;
	    if ($data =~ m/\n/) {
		$line = $data;
	    }
	    else {
		$data = $line.$data;
	    }
	    $this->tlInstInfo->setText($data);
	}
	else {
	    sleep(1);
	}
    }
    close(LOG);
}


sub doLoaderInstall # SLOT: ( )
{
    my $kernelver = qx(uname -r);
    chomp($kernelver);
    my $kernel = "/boot/vmlinuz-".$kernelver;
    my $initrd = "/boot/initrd-".$kernelver.".img";
    my $distro = qx(cat /etc/redhat-release | awk '{ print \$1 }');
    chomp($distro);

    my $bootstr = lbBootloader->selectedItem()->text();
    my ($bdev, $text) = split(/ /, $bootstr);
    $bootdev = $bdev;

    open LILO, '>', "$mnt/etc/lilo.conf";
    print LILO "boot=$bootdev
map=/boot/map
default=\"$distro\"
keytable=/boot/us.klt
prompt
nowarn
timeout=100
message=/boot/message
menu-scheme=wb:bw:wb:bw
image=$kernel
	label=\"$distro\"
	root=$rootpart
	initrd=$initrd
	append=\"devfs=mount splash=silent\"
	vga=791
	read-only
";
    close LILO;
    system("mount -t proc none $mnt/proc");
    system("mount -t devfs none $mnt/dev");
    system("rm -rf $mnt/$initrd");
    system("mkdir -p $mnt/root/tmp");
    my $with = "";
    system("chroot $mnt /sbin/mkinitrd -v $with $initrd $kernelver");
    system("/sbin/lilo -v -r $mnt");
    system("umount $mnt/dev");
    system("umount $mnt/proc");

    emit this->next();
}


sub writeFstab {
    my ($devs) = @_;

    my @fstab = fs::read_fstab("", "/etc/fstab");
    my $hdds = {};
    fs::add2all_hds($hdds, @fstab);
    fs::write_fstab($hdds, $mnt);

    open FSTAB, '>', "$mnt/etc/fstab";
    print FSTAB "\n### entries below this line were automatically added by LiveCD install\n";
    print FSTAB "\nnone"."\t"."/proc"."\t"."proc"."\t"."defaults"."\t"."0 0";
    print FSTAB "\nnone"."\t"."/dev"."\t"."devfs"."\t"."defaults"."\t"."0 0";
    print FSTAB "\n";

    foreach my $dev (sort keys %$devs) {
	my $devpnt = $dev;
	$devpnt =~ s|/dev/||;
	system("mkdir -p $mnt/mnt/$devpnt 2>/dev/null");

	my $mount = "";
	my $opt = undef;
	if ($dev eq $rootpart) {
	    $mount = "/";
	    $opt = $fsopts{$devs->{$dev}{type}};
	}
	elsif ($dev eq $homepart) {
	    $mount = "/home";
	    $opt = $fsopts{$devs->{$dev}{type}};
	}
	elsif ($dev eq $varpart) {
	    $mount = "/var";
	    $opt = $fsopts{$devs->{$dev}{type}};
	}
	elsif ($dev eq $tmppart) {
	    $mount = "/tmp";
	    $opt = $fsopts{$devs->{$dev}{type}};
	}
	else {
	    $mount = $devs->{$dev}{mount};
	    $opt = $devs->{$dev}{opt};
	}

	print FSTAB "\n# ".$devs->{$dev}{info};
	my $entry = "\n";
	$entry .= $devs->{$dev}{devfs}."\t";
	$entry .= $mount."\t";
	$entry .= $devs->{$dev}{type}."\t";
	$opt = "" unless ($opt);
	if ($devs->{$dev}{extopt}) {
	    $opt .= "," ;
	    $opt .= $devs->{$dev}{extopt};
	}
	$entry .= $opt."\t"."0 0\n";
	print FSTAB $entry;
    }
    close FSTAB;
}


sub toggleReboot # SLOT: ( bool )
{
    my ($check) = @_;

    if (defined($check)) {
	$reboot = ($check eq 1) ? 1 : undef;
    }
    else {
	$reboot = undef;
    }
}
