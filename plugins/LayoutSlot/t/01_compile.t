use FindBin;
use lib "$FindBin::Bin";

use MTPath;
use Test::More;

use_ok 'MT::Template::LayoutSlot::Tags';
use_ok 'MT::Template::LayoutSlot::CMS';

done_testing;