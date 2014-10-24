use warnings;
use strict;

BEGIN {
	eval { require Scope::Upper };
	if($@ ne "") {
		require Test::More;
		Test::More::plan(skip_all => "no Scope::Upper");
	}
	*reap = \&Scope::Upper::reap;
}

use Test::More tests => 3;

BEGIN { use_ok "Scope::Escape", qw(current_escape_function); }

BEGIN { Scope::Escape::_set_sanity_checking(1); }

my($cont, @value, @events);

$cont = undef; @events = ();
push @events, ["a0"];
@value = eval {
	push @events, ["b0"];
	@value = sub {
		push @events, ["c0"];
		$cont = current_escape_function;
		push @events, ["c1"];
		@value = sub {
			push @events, ["d0"];
			reap {
				push @events, ["e0"];
				die "e1\n";
				push @events, ["e2"];
			};
			push @events, ["d1"];
			$cont->("d2a", "d2b");
			push @events, ["d3"];
			("d4a", "d4b");
		}->();
		push @events, ["c2"];
		("c3a", "c3b");
	}->();
	push @events, ["b2", [@value]];
	("b3a", "b3b");
};
push @events, ["a1", [@value], $@];
is_deeply \@events, [
	["a0"],
	["b0"],
	["c0"],
	["c1"],
	["d0"],
	["d1"],
	["e0"],
	["a1", [], "e1\n"],
];

$cont = undef; @events = ();
push @events, ["a0"];
@value = sub {
	push @events, ["b0"];
	$cont = current_escape_function;
	push @events, ["b1"];
	@value = eval {
		push @events, ["c0"];
		@value = sub {
			push @events, ["d0"];
			reap {
				push @events, ["e0"];
				$cont->("e1a", "e1b");
				push @events, ["e2"];
			};
			push @events, ["d1"];
			die "d2\n";
			push @events, ["d3"];
			("d4a", "d4b");
		}->();
		push @events, ["c2"];
		("c3a", "c3b");
	};
	push @events, ["b2", [@value], $@];
	("b3a", "b3b");
}->();
push @events, ["a1", [@value]];
is_deeply \@events, [
	["a0"],
	["b0"],
	["b1"],
	["c0"],
	["d0"],
	["d1"],
	["e0"],
	["a1", ["e1a", "e1b"]],
];

1;
