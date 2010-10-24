use 5.12.0;
use warnings;

use lib 't/lib';
#use Devel::Cover qw(-silent 1);

use WebService::LOC::CongRec::DayTest;
use WebService::LOC::CongRec::PageTest;
use WebService::LOC::CongRec::UtilTest;

Test::Class->runtests();
