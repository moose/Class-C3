use strict;
use warnings FATAL => 'all';
use 5.006;

my %META = (
  name => 'Class-C3',
  license => 'perl_5',
  prereqs => {
    configure => { requires => {
      'ExtUtils::MakeMaker'   => 0,
      'ExtUtils::CBuilder'    => 0.27,
    } },
    build => { requires => {
    } },
    test => {
      requires => {
        'Test::More' => '0.47',
      },
    },
    runtime => {
      requires => {
        'Algorithm::C3' => '0.07',
        'Scalar::Util'  => '0',
        'perl'          => 5.006,
      },
    },
    develop   => {
      requires => { map { $_ => 0 } qw(
        indirect multidimensional bareword::filehandles
        Moose Mouse namespace::clean namespace::autoclean
        MooseX::Types::Common::Numeric
        Type::Tiny
      ) },
    },
  },
  resources => {
    repository => {
      url => 'git://git.shadowcat.co.uk/gitmo/Class-C3.git',
      web => 'http://git.shadowcat.co.uk/gitweb/gitweb.cgi?p=gitmo/Class-C3.git',
      type => 'git',
    },
    bugtracker => {
      web => 'https://rt.cpan.org/Public/Dist/Display.html?Name=Class-C3',
      mailto => 'bug-Class-C3@rt.cpan.org',
    },
    homepage => 'https://metacpan.org/release/Class-C3',
    license => [ 'http://dev.perl.org/licenses/' ],
  },
  no_index => {
    directory => [ 't', 'xt', 'opt' ]
  },
);

my %MM_ARGS = (
  TEST_REQUIRES => {
    ( $] < 5.009_005 and is_smoker() )
      ? ( 'Devel::Hide' => 0 ) : ()
  },
  PREREQ_PM => {
    ( $] < 5.009_005 and can_xs() )
      ? ( 'Class::C3::XS'  => '0.13' ) : ()
  },
);

##############################################################################
require ExtUtils::MakeMaker;
(do 'maint/Makefile.PL.include' or die $@) unless -f 'META.yml';

# have to do this since old EUMM dev releases miss the eval $VERSION line
my $eumm_version  = eval $ExtUtils::MakeMaker::VERSION;
my $mymeta        = $eumm_version >= 6.57_02;
my $mymeta_broken = $mymeta && $eumm_version < 6.57_07;

($MM_ARGS{NAME} = $META{name}) =~ s/-/::/g;
($MM_ARGS{VERSION_FROM} = "lib/$MM_ARGS{NAME}.pm") =~ s{::}{/}g;
$MM_ARGS{LICENSE} = $META{license}
  if $eumm_version >= 6.30;
$MM_ARGS{NO_MYMETA} = 1
  if $mymeta_broken;
$MM_ARGS{META_ADD} = { 'meta-spec' => { version => 2 }, %META }
  unless -f 'META.yml';

for (qw(configure build test runtime)) {
  my $key = $_ eq 'runtime' ? 'PREREQ_PM' : uc $_.'_REQUIRES';
  my $r = $MM_ARGS{$key} = {
    %{$META{prereqs}{$_}{requires} || {}},
    %{delete $MM_ARGS{$key} || {}},
  };
  defined $r->{$_} or delete $r->{$_} for keys %$r;
}

$MM_ARGS{MIN_PERL_VERSION} = delete $MM_ARGS{PREREQ_PM}{perl} || 0;

delete $MM_ARGS{MIN_PERL_VERSION}
  if $eumm_version < 6.47_01;
$MM_ARGS{BUILD_REQUIRES} = {%{$MM_ARGS{BUILD_REQUIRES}}, %{delete $MM_ARGS{TEST_REQUIRES}}}
  if $eumm_version < 6.63_03;
$MM_ARGS{PREREQ_PM} = {%{$MM_ARGS{PREREQ_PM}}, %{delete $MM_ARGS{BUILD_REQUIRES}}}
  if $eumm_version < 6.55_01;
delete $MM_ARGS{CONFIGURE_REQUIRES}
  if $eumm_version < 6.51_03;

ExtUtils::MakeMaker::WriteMakefile(%MM_ARGS);
##############################################################################

# Secondary compile testing via ExtUtils::CBuilder
sub can_xs {
  # Do we have the configure_requires checker?
  local $@;
  eval "require ExtUtils::CBuilder;";
  if ( $@ ) {
    # They don't obey configure_requires, so it is
    # someone old and delicate. Try to avoid hurting
    # them by falling back to an older simpler test.
    return can_cc();
  }

  return ExtUtils::CBuilder->new( quiet => 1 )->have_compiler;
}

# can we locate a (the) C compiler
sub can_cc {
  my @chunks = split(/ /, $Config::Config{cc}) or return;

  # $Config{cc} may contain args; try to find out the program part
  while (@chunks) {
    return can_run("@chunks") || (pop(@chunks), next);
  }

  return;
}

# check if we can run some command
sub can_run {
  my ($cmd) = @_;

  return $cmd if -x $cmd;
  if (my $found_cmd = MM->maybe_command($cmd)) {
    return $found_cmd;
  }

  for my $dir ((split /$Config::Config{path_sep}/, $ENV{PATH}), '.') {
    next if $dir eq '';
    my $abs = File::Spec->catfile($dir, $cmd);
    return $abs if (-x $abs or $abs = MM->maybe_command($abs));
  }

  return;
}

sub is_smoker {
  return ( $ENV{AUTOMATED_TESTING} && ! $ENV{PERL5_CPANM_IS_RUNNING} && ! $ENV{RELEASE_TESTING} )
}
