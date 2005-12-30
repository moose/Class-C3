#!/usr/bin/perl

use strict;
use warnings;

use Test::More tests => 7;

BEGIN {
    use lib 'opt', '../opt', '..';    
    use_ok('c3');
    # uncomment this line, and re-run the
    # test to see the normal p5 dispatch order
    #$Class::C3::TURN_OFF_C3 = 1;    
}

=pod

This tests the classic diamond inheritence pattern.

   <A>
  /   \
<B>   <C>
  \   /
   <D>

=cut

{
    package Diamond_A;
    use c3; 
    sub bar { 'Diamond_A::bar' }        
    sub baz { 'Diamond_A::baz' }
}
{
    package Diamond_B;
    use base 'Diamond_A';
    use c3;    
    sub baz { 'Diamond_B::baz => ' . (shift)->next::method() }         
}
{
    package Diamond_C;
    use c3;    
    use base 'Diamond_A';     
    sub foo { 'Diamond_C::foo' }   
    sub buz { 'Diamond_C::buz' }           
}
{
    package Diamond_D;
    use base ('Diamond_B', 'Diamond_C');
    use c3; 
    sub foo { 'Diamond_D::foo => ' . (shift)->next::method() } 
    sub bar { 'Diamond_D::bar => ' . (shift)->next::method() }   
    sub buz { 'Diamond_D::buz => ' . (shift)->baz() }  
    sub fuz { 'Diamond_D::fuz => ' . (shift)->next::method() }           

}

is_deeply(
    [ Class::C3::calculateMRO('Diamond_D') ],
    [ qw(Diamond_D Diamond_B Diamond_C Diamond_A) ],
    '... got the right MRO for Diamond_D');

is(Diamond_D->foo, 'Diamond_D::foo => Diamond_C::foo', '... skipped B and went to C correctly');
is(Diamond_D->bar, 'Diamond_D::bar => Diamond_A::bar', '... skipped B & C and went to A correctly');
is(Diamond_D->baz, 'Diamond_B::baz => Diamond_A::baz', '... called B method, skipped C and went to A correctly');
is(Diamond_D->buz, 'Diamond_D::buz => Diamond_B::baz => Diamond_A::baz', '... called D method dispatched to , different method correctly');
eval { Diamond_D->fuz };
like($@, qr/^No next::method 'fuz' found for Diamond_D/, '... cannot re-dispatch to a method which is not there');

