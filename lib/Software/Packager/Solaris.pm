=head1 NAME

Software::Packager::Solaris - Software packager for the Solaris platform.

=head1 SYNOPSIS

 use Software::Packager;
 my $packager = new Software::Packager('solaris');

=head1 DESCRIPTION

This module is used to create software packages in a format suitable for
installation with pkgadd.
The process of creating packages is baised upon the document 
Application Packaging Developer's Guide. Which can be found at
http://docs.sun.com/ab2/@LegacyPageView?toc=SUNWab_42_2:/safedir/space3/coll1/SUNWasup/toc/PACKINSTALL:Contents;bt=Application+Packaging+Developer%27s+Guide;ps=ps/SUNWab_42_2/PACKINSTALL/Contents

=head1 FUNCTIONS

=cut

package		Software::Packager::Solaris;

####################
# Standard Modules
use strict;
use File::Copy;
use File::Path;
use File::Basename;
use FileHandle 2.0;
#use Cwd;
# Custom modules
use Software::Packager;
use Software::Packager::Object::Solaris;

####################
# Variables
our @ISA = qw( Software::Packager );
our @EXPORT = qw();
our @EXPORT_OK = qw();
our $VERSION = 0.06;

####################
# Functions

################################################################################
# Function:	new()

=head1 B<new()>

This method creates and returns a new Software::Packager::Solaris object.

=cut
sub new
{
	my $class = shift;
	my $self = bless {}, $class;

	return $self;
}

################################################################################
# Function:	add_item()

=head1 B<add_item()>

$packager->add_item(%object_data);
This method overrides the add_item function in the Software::Packager module.
This method adds a new object to the package.

=cut
sub add_item
{
	my $self = shift;
	my %data = @_;
	my $object = new Software::Packager::Object::Solaris(%data);

	return undef unless $object;

	# check that the object has a unique destination
	return undef if $self->{'OBJECTS'}->{$object->destination()};

	return 1 if $self->{'OBJECTS'}->{$object->destination()} = $object;
	return undef;
}

################################################################################
# Function:	_package_name()

=head2 B<_package_name()>

This method overrides the _package_name method in Software::Packager.
It is used to truncate the package name if it is longer than 9 charaters and
return it.

=cut
sub _package_name
{
	my $self = shift;
	my $name =  $self->{'PACKAGE_NAME'};
	if (length $name > 9)
	{
		my $new_name = sprintf ("%.9s", $name);
		warn "Warning: Package name is to long. Truncating to $new_name\n";
		return $new_name;
	}
	else
	{
		return $self->{'PACKAGE_NAME'};
	}
}

################################################################################
# Function:	package()

=head2 B<package()>

$packager->packager();
This method overrides the base API in Software::Packager, it controls the
process if package creation.

=cut
sub package
{
	my $self = shift;

	# setup the tmp structure
	return undef unless $self->_setup_in_tmp();

	# Create the package
	return undef unless $self->_create_package();

	# remove tmp structure
	return undef unless $self->_remove_tmp();

	return 1;
}

################################################################################
# Function:	_setup_in_tmp()
# Description:	This function sets up the temporary structure for the package.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub _setup_in_tmp
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	# process directories
	unless (-d $tmp_dir)
	{
		return undef unless mkpath($tmp_dir, 0, 0777);
	}

	# process files
	if ($self->license_file())
	{
		return undef unless copy($self->license_file(), "$tmp_dir/copyright");
	}

	return 1;
}

################################################################################
# Function:	create_package()
# Description:	This function creates the package
# Arguments:	none.
# Return:	true if ok else undef.
#
sub _create_package
{
	my $self = shift;

	# create the prototype file
	return undef unless $self->_create_prototype();

	# create the pkginfo file
	return undef unless $self->_create_pkginfo();

	# make the package
	return undef unless $self->_create_pkgmk();

	return 1;
}

################################################################################
# Function:	_remove_tmp()
# Description:	This function removes the temporary structure for the package.
# Arguments:	none.
# Return:	true if ok else undef.
#
sub _remove_tmp
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	return undef unless system("chmod -R 0777 $tmp_dir") eq 0;
	rmtree($tmp_dir, 0, 1);
	return 1;
}

################################################################################
# Function:	_create_prototype()
# Description:	This function create the prototype file
# Arguments:	none.
# Return:	true if ok else undef.
#
sub _create_prototype
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	my $protofile = new FileHandle() or return undef;
	return undef unless $protofile->open(">$tmp_dir/prototype");

	$protofile->print("i pkginfo\n");
	$protofile->print("i copyright\n") if $self->license_file();

	# add the directories then files then links
	foreach my $object ($self->get_directory_objects(), $self->get_file_objects(), $self->get_link_objects())
	{
		$protofile->print($object->part(), " ");
		$protofile->print($object->prototype(), " ");
		$protofile->print($object->class(), " ");
		if ($object->prototype() =~ /[dx]/)
		{
			$protofile->print($object->destination(), " ");
		}
		else
		{
			$protofile->print($object->destination(), "=");
			$protofile->print($object->source(), " ");
		}
		$protofile->print($object->mode(), " ");
		$protofile->print($object->user(), " ");
		$protofile->print($object->group(), "\n");
	}

	return undef unless $protofile->close();
	return 1;
}

################################################################################
# Function:	_create_pkginfo()
# Description:	This function creates the pkginfo file
# Arguments:	none.
# Return:	true if ok else undef.
#
sub _create_pkginfo
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();

	my $protofile = new FileHandle() or return undef;
	return undef unless $protofile->open(">$tmp_dir/pkginfo");
	return undef unless $protofile->print("PKG=\"", $self->package_name(), "\"\n");
	return undef unless $protofile->print("NAME=\"", $self->program_name(), "\"\n");
	return undef unless $protofile->print("ARCH=\"", $self->architecture(), "\"\n");
	return undef unless $protofile->print("VERSION=\"", $self->version(), "\"\n");
	return undef unless $protofile->print("CATEGORY=\"", $self->category(), "\"\n");
	return undef unless $protofile->print("VENDOR=\"", $self->vendor(), "\"\n");
	return undef unless $protofile->print("EMAIL=\"", $self->email_contact(), "\"\n");
	return undef unless $protofile->print("PSTAMP=\"", $self->creator(), "\"\n");
	return undef unless $protofile->print("BASEDIR=\"", $self->install_dir(), "\"\n");
	return undef unless $protofile->print("CLASSES=\"none\"\n");
	return undef unless $protofile->close();

	return 1;
}

################################################################################
# Function:	_create_package()
# Description:	This function creates the package and puts it in the output
#		directory
# Arguments:	none.
# Return:	true if ok else undef.
#
sub _create_pkgmk
{
	my $self = shift;
	my $tmp_dir = $self->tmp_dir();
	my $output_dir = $self->output_dir();
	my $name = $self->package_name();

	unless (-d $output_dir)
	{
		return undef unless mkpath($output_dir, 0, 0777);
	}

	return undef unless system("pkgmk -r / -f $tmp_dir/prototype ") eq 0;
	return undef unless system("pkgtrans -s /var/spool/pkg $output_dir/$name $name") eq 0;

	# clean up our neat mess.
	return undef unless system("chmod -R 0700 /var/spool/pkg/$name") eq 0;
	rmtree("/var/spool/pkg/$name", 0, 1);

	return 1;
}

1;
__END__

=head1 SEE ALSO

Software::Packager
Software::Packager::Object::Solaris

=head1 AUTHOR

R Bernard Davison <rbdavison@cpan.org>

=head1 HOMEPAGE

http://bernard.gondwana.com.au

=head1 COPYRIGHT

Copyright (c) 2001 Gondwanatech. All rights reserved.
This program is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut

