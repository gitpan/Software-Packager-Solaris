# t/05_solaris.t; load Software::Packager and create a Solaris package

$|++; 
use Software::Packager;
use Cwd;
use Config;
use File::Path;
use Data::Dumper;
my $test_number = 1;
my $comment = "";

if ($Config{'osname'} =~ /solaris/i)
{
	if ($> ne 0)
	{
		print "1..0\n";
		warn "Root access is required to create packages on solaris. ";
		exit 0;
	}
	else
	{
		print "1..20\n";
	}
}
else
{
	print "1..0\n";
	exit 0;
}

# test 1
my $packager = new Software::Packager();
print_status($packager);

# test 2
$packager->package_name('SolarisTestPackage');
my $package_name = $packager->package_name();
same($package_name, 'SolarisTe');

# test 3
$packager->program_name('Software Packager');
my $program_name = $packager->program_name();
same($program_name, 'Software Packager');

# test 4
$packager->description("This is a description");
my $description = $packager->description();
same($description, "This is a description");

# test 5
$packager->version('1.0.0');
my $version = $packager->version();
same($version, '1.0.0');

# test 6
my $cwd_output_dir = getcwd();
$packager->output_dir($cwd_output_dir);
my $output_dir = $packager->output_dir();
same($output_dir, "$cwd_output_dir");

# test 7
$packager->category("Applications");
my $category = $packager->category();
same($category, "Applications");

# test 8
$packager->architecture("None");
my $architecture = $packager->architecture();
same($architecture, "None");

# test 9
$packager->icon("t/test_icon.tiff");
my $icon = $packager->icon();
same($icon, "t/test_icon.tiff");

# test 10
$packager->prerequisites("None");
my $prerequisites = $packager->prerequisites();
same($prerequisites, "None");

# test 11
$packager->vendor("Gondwanatech");
my $vendor = $packager->vendor();
same($vendor, "Gondwanatech");

# test 12
$packager->email_contact('bernard@gondwana.com.au');
my $email_contact = $packager->email_contact();
same($email_contact, 'bernard@gondwana.com.au');

# test 13
$packager->creator('R Bernard Davison');
my $creator = $packager->creator();
same($creator, 'R Bernard Davison');

# test 14
$packager->install_dir("perllib");
my $install_dir = $packager->install_dir();
same($install_dir, "perllib");

# test 15
$packager->tmp_dir("t/solaris_tmp_build_dir");
my $tmp_dir = $packager->tmp_dir();
same($tmp_dir, "t/solaris_tmp_build_dir");

# test 16
# so we have finished the configuration so add the objects.
open (MANIFEST, "< MANIFEST") or warn "Cannot open MANIFEST: $!\n";
my $add_status = 1;
my $cwd = getcwd();
while (<MANIFEST>)
{
	my $file = $_;
	chomp $file;
	my @stats = stat $file;
	my %data;
	$data{'TYPE'} = 'File';
	$data{'TYPE'} = 'Directory' if -d $file;
	$data{'SOURCE'} = "$cwd/$file";
	$data{'DESTINATION'} = $file;
	$data{'MODE'} = sprintf "%04o", $stats[2] & 07777;
	$add_status = undef unless $packager->add_item(%data);
}
close MANIFEST;
foreach my $dir  ("lib", "lib/Software", "lib/Software/Packager", "lib/Software/Packager/Object", "t")
{
	my @stats = stat $dir;
	my %data;
	$data{'TYPE'} = 'Directory';
	$data{'DESTINATION'} = $dir;
	$data{'MODE'} = sprintf "%04o", $stats[2] & 07777;
	$add_status = undef unless $packager->add_item(%data);
}
print_status($add_status);

#warn Dumper($packager);
# test 17
my %hardlink;
$hardlink{'TYPE'} = 'Hardlink';
$hardlink{'SOURCE'} = "lib/Software/Packager.pm";
$hardlink{'DESTINATION'} = "HardLink.pm";
print_status($packager->add_item(%hardlink));

# test 18
my %softlink;
$softlink{'TYPE'} = 'softlink';
$softlink{'SOURCE'} = "lib/Software";
$softlink{'DESTINATION'} = "SoftLink";
print_status($packager->add_item(%softlink));

# test 19
print_status($packager->package());

# test 20
my $package_file = $packager->output_dir();
$package_file .= "/" . $packager->package_name();
$comment = "Should have created $package_file";
print_status(-f $package_file);

system("chmod -R 0777 $package_file");
rmtree($package_file, 1, 1);

####################
# Functions to use
sub same
{
	my $expected = shift;
	my $got = shift;
	if ($expected eq $got)
	{
		print_status(1);
	}
	else
	{
		$comment = " # Expected:\"$expected\" but Got:\"$got\"" unless $comment;
		print_status(0, $comment);
	}
	$comment = "";
}

sub print_status
{
	my $value = shift;
	if ($value)
	{
		print "ok $test_number\n";
	}
	else
	{
		print "not ok $test_number $comment\n";
	}
	$test_number++;
	$comment = "";
}

