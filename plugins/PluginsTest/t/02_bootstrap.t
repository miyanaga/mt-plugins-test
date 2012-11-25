use strict;
use warnings;

use FindBin qw($Bin);
use lib $Bin;

use SelfTest via => 'bootstrap';

SelfTest->run;
