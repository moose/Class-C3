use strict;
use warnings;
use 5.006;

use ExtUtils::MakeMaker;

my $mymeta_works = eval { ExtUtils::MakeMaker->VERSION('6.5707'); 1 };
my $mymeta = $mymeta_works || eval { ExtUtils::MakeMaker->VERSION('6.5702'); 1 };

my %BUILD_DEPS = (
  'Test::More' => '0.47',
);
my %OPT_BUILD_DEPS = ( $] < 5.009_005 and is_smoker() )
  ? ( 'Devel::Hide' => 0 ) : ()
;

my %RUN_DEPS = (
  # needed by the PP version only, have them installed
  # regardless of XS availability or perl version
  # (for fatpacking and whatnot)
  'Algorithm::C3' => '0.07',
  'Scalar::Util'  => '0',
);
my %OPT_RUN_DEPS = ( $] < 5.009_005 and can_xs() )
  ? ( 'Class::C3::XS'  => '0.13' ) : ()
;

my %META_BITS = (
  resources => {
    homepage => 'http://search.cpan.org/dist/Class-C3',
    repository => 'git://git.shadowcat.co.uk/gitmo/Class-C3.git',
    bugtracker => 'http://rt.cpan.org/Public/Dist/Display.html?Name=Class-C3',
  },
);

my %WriteMakefileArgs = (
  'NAME' => 'Class::C3',
  'AUTHOR' => 'Stevan Little, <stevan@iinteractive.com>',
  'VERSION_FROM' => 'lib/Class/C3.pm',
  'ABSTRACT_FROM' => 'lib/Class/C3.pm',
  'CONFIGURE_REQUIRES' => { 'ExtUtils::CBuilder' => 0.27 },
  'PREREQ_PM' => {
    %RUN_DEPS, %OPT_RUN_DEPS,
    $mymeta_works ? () : (%BUILD_DEPS, %OPT_BUILD_DEPS),
  },

  $mymeta_works
    ? ( # BUILD_REQUIRES makes MYMETA right, requires stops META being wrong
      'BUILD_REQUIRES' => { %BUILD_DEPS, %OPT_BUILD_DEPS },
      'META_ADD' => {
        %META_BITS,
        requires => \%RUN_DEPS,
      },
    )
    : ( # META_ADD both to get META right - only Makefile written
      'META_ADD' => {
        %META_BITS,
        requires => \%RUN_DEPS,
        build_requires => \%BUILD_DEPS,
      },
    )
  ,

  ($mymeta and !$mymeta_works) ? ( 'NO_MYMETA' => 1 ) : (),

  'LICENSE' => 'perl',
);


unless ( eval { ExtUtils::MakeMaker->VERSION('6.56') } ) {
  my $br = delete $WriteMakefileArgs{BUILD_REQUIRES};
  my $pp = $WriteMakefileArgs{PREREQ_PM};
  for my $mod ( keys %$br ) {
    if ( exists $pp->{$mod} ) {
       $pp->{$mod} = $br->{$mod} if $br->{$mod} > $pp->{$mod};
    }
    else {
      $pp->{$mod} = $br->{$mod};
    }
  }
}

delete $WriteMakefileArgs{CONFIGURE_REQUIRES}
  unless eval { ExtUtils::MakeMaker->VERSION('6.52') };

system("pod2text lib/Class/C3.pm >README")
    unless -f 'META.yml';

WriteMakefile(%WriteMakefileArgs);

# Secondary compile testing via ExtUtils::CBuilder
sub can_xs {
  # Do we have the configure_requires checker?
  local $@;
  eval "require ExtUtils::CBuilder;";
  if (! $@ ) {
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
