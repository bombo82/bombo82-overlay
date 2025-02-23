# Copyright 2019-2021 Gianni Bombelli <bombo82@giannibombelli.it>
# Distributed under the terms of the GNU General Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option) any later version.

EAPI=8

inherit acct-user

DESCRIPTION="User for sys-devel/icecream"
KEYWORDS="~amd64 ~arm ~arm64 ~ppc ~ppc64 ~x86"

ACCT_USER_ID=-1
ACCT_USER_GROUPS=( icecream )

acct-user_add_deps
