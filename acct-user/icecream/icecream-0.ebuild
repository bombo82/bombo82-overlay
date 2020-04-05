# Copyright 2019 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License  as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=7

inherit acct-user

KEYWORDS="~amd64 ~arm ~hppa ~ppc ~x86"

DESCRIPTION="User for sys-devel/icecream"
ACCT_USER_ID=-1
ACCT_USER_HOME=/var/cache/icecream
ACCT_USER_GROUPS=( icecream )

acct-user_add_deps
