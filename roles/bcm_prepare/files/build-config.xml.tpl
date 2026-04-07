<?xml version="1.0" encoding="ISO-8859-1"?>
<Cluster>
  <cmid>286032</cmid>
  <organization>NVIDIA</organization>
  <clustername>BCM 11.0 Cluster</clustername>
  <racks>1</racks>
  <rackheight>42</rackheight>
  <dnsdomain>brightcomputing.com</dnsdomain>
  <timeserver>0.pool.ntp.org</timeserver>
  <timeserver>1.pool.ntp.org</timeserver>
  <timeserver>2.pool.ntp.org</timeserver>
  <timezone>{{ timezone }}</timezone>
  <admin/>
  <sendadminemailfirstboot/>
  <basename>node</basename>
  <nodestartnum>1</nodestartnum>
  <digits>3</digits>
{% for net in networks %}
  <Network>
    <name>{{ net.name }}</name>
    <base>{{ net.base }}</base>
    <netmaskbits>{{ net.maskbits }}</netmaskbits>
    <dnsdomain>{{ net.domain }}</dnsdomain>
{% if net.type == 'internal' %}
    <bootable/>
    <dynamicrangestart>{{ net.dyn_start }}</dynamicrangestart>
    <dynamicrangeend>{{ net.dyn_end }}</dynamicrangeend>
{% endif %}
{% if net.gateway is defined %}
    <gateway>{{ net.gateway }}</gateway>
{% endif %}
{% if net.type == 'external' %}
    <external/>
    <disableAutomaticExports>yes</disableAutomaticExports>
{% endif %}
    <type>{{ net.type }}</type>
  </Network>
{% endfor %}
  <managementnetwork>internalnet</managementnetwork>
  <MasterConfig>
    <arch>x86_64</arch>
    <basedist>UBUNTU2404</basedist>
    <kernel>DEFAULT</kernel>
    <custom_finalize><![CDATA[#The filesystem of the master node is mounted under /mnt/hd]]></custom_finalize>
    <custom_finalise><![CDATA[#The filesystem of the master node is mounted under /mnt/hd]]></custom_finalise>
    <baserpmstore>dist/ubuntu/2404</baserpmstore>
    <cmrpmstore>11.31.1/ubuntu/2404</cmrpmstore>
    <baserpm install="yes" arch="all">python3-html5lib</baserpm>
    <baserpm install="yes" arch="all">manpages</baserpm>
    <baserpm install="yes" arch="all">python3-pip</baserpm>
    <baserpm install="yes" arch="all">python-is-python3</baserpm>
    <baserpm install="yes" arch="all">libnet-smtp-ssl-perl</baserpm>
    <baserpm install="yes" arch="all">libdata-dump-perl</baserpm>
    <baserpm install="yes" arch="all">python3-openssl</baserpm>
    <baserpm install="yes" arch="all">libhtml-template-perl</baserpm>
    <baserpm install="yes" arch="all">libsource-highlight-common</baserpm>
    <baserpm install="yes" arch="all">python3-cssselect</baserpm>
    <baserpm install="yes" arch="all">dh-autoreconf</baserpm>
    <baserpm install="yes" arch="all">libdebhelper-perl</baserpm>
    <baserpm install="yes" arch="all">python3-chardet</baserpm>
    <baserpm install="yes" arch="all">fonts-liberation</baserpm>
    <baserpm install="yes" arch="all">at-spi2-common</baserpm>
    <baserpm install="yes" arch="all">po-debconf</baserpm>
    <baserpm install="yes" arch="all">wireless-regdb</baserpm>
    <baserpm install="yes" arch="all">python3-soupsieve</baserpm>
    <baserpm install="yes" arch="all">libtirpc-common</baserpm>
    <baserpm install="yes" arch="all">liblwp-mediatypes-perl</baserpm>
    <baserpm install="yes" arch="all">libio-socket-inet6-perl</baserpm>
    <baserpm install="yes" arch="all">python3-jaraco.classes</baserpm>
    <baserpm install="yes" arch="all">libxml-sax-expat-perl</baserpm>
    <baserpm install="yes" arch="all">alsa-topology-conf</baserpm>
    <baserpm install="yes" arch="all">ifenslave</baserpm>
    <baserpm install="yes" arch="all">mecab-ipadic-utf8</baserpm>
    <baserpm install="yes" arch="all">dh-strip-nondeterminism</baserpm>
    <baserpm install="yes" arch="all">shorewall-core</baserpm>
    <baserpm install="yes" arch="all">mailutils-common</baserpm>
    <baserpm install="yes" arch="all">geoip-database</baserpm>
    <baserpm install="yes" arch="all">xbitmaps</baserpm>
    <baserpm install="yes" arch="all">libauthen-sasl-perl</baserpm>
    <baserpm install="yes" arch="all">libxml-namespacesupport-perl</baserpm>
    <baserpm install="yes" arch="all">python3-ptyprocess</baserpm>
    <baserpm install="yes" arch="all">python3-jeepney</baserpm>
    <baserpm install="yes" arch="all">libjson-perl</baserpm>
    <baserpm install="yes" arch="all">lua-json</baserpm>
    <baserpm install="yes" arch="all">fonts-liberation2</baserpm>
    <baserpm install="yes" arch="all">parallel</baserpm>
    <baserpm install="yes" arch="all">fonts-liberation-sans-narrow</baserpm>
    <baserpm install="yes" arch="all">libalgorithm-merge-perl</baserpm>
    <baserpm install="yes" arch="all">libencode-locale-perl</baserpm>
    <baserpm install="yes" arch="all">libhtml-format-perl</baserpm>
    <baserpm install="yes" arch="all">libio-string-perl</baserpm>
    <baserpm install="yes" arch="all">libmailtools-perl</baserpm>
    <baserpm install="yes" arch="all">libfile-stripnondeterminism-perl</baserpm>
    <baserpm install="yes" arch="all">python3-asn1crypto</baserpm>
    <baserpm install="yes" arch="all">xfonts-base</baserpm>
    <baserpm install="yes" arch="all">libstring-shellquote-perl</baserpm>
    <baserpm install="yes" arch="all">libhttp-negotiate-perl</baserpm>
    <baserpm install="yes" arch="all">javascript-common</baserpm>
    <baserpm install="yes" arch="all">python3-pexpect</baserpm>
    <baserpm install="yes" arch="all">sound-theme-freedesktop</baserpm>
    <baserpm install="yes" arch="all">python3-importlib-metadata</baserpm>
    <baserpm install="yes" arch="all">libatk-wrapper-java</baserpm>
    <baserpm install="yes" arch="all">python3-pyasn1</baserpm>
    <baserpm install="yes" arch="all">ntp</baserpm>
    <baserpm install="yes" arch="all">xfonts-encodings</baserpm>
    <baserpm install="yes" arch="all">libsensors-config</baserpm>
    <baserpm install="yes" arch="all">libxml-sax-base-perl</baserpm>
    <baserpm install="yes" arch="all">gsasl-common</baserpm>
    <baserpm install="yes" arch="all">shorewall</baserpm>
    <baserpm install="yes" arch="all">libcgi-fast-perl</baserpm>
    <baserpm install="yes" arch="all">libparse-debian-packages-perl</baserpm>
    <baserpm install="yes" arch="all">libhttp-date-perl</baserpm>
    <baserpm install="yes" arch="all">libhttp-daemon-perl</baserpm>
    <baserpm install="yes" arch="all">apache2-data</baserpm>
    <baserpm install="yes" arch="all">libarchive-zip-perl</baserpm>
    <baserpm install="yes" arch="all">cryptsetup-initramfs</baserpm>
    <baserpm install="yes" arch="all">python3-webencodings</baserpm>
    <baserpm install="yes" arch="all">autopoint</baserpm>
    <baserpm install="yes" arch="all">cgroup-lite</baserpm>
    <baserpm install="yes" arch="all">postgresql-client</baserpm>
    <baserpm install="yes" arch="all">python3-six</baserpm>
    <baserpm install="yes" arch="all">alsa-ucm-conf</baserpm>
    <baserpm install="yes" arch="all">glib-networking-common</baserpm>
    <baserpm install="yes" arch="all">libfile-listing-perl</baserpm>
    <baserpm install="yes" arch="all">liburi-perl</baserpm>
    <baserpm install="yes" arch="all">python3-idna</baserpm>
    <baserpm install="yes" arch="all">python3-pkg-resources</baserpm>
    <baserpm install="yes" arch="all">gsettings-desktop-schemas</baserpm>
    <baserpm install="yes" arch="all">liblwp-protocol-https-perl</baserpm>
    <baserpm install="yes" arch="all">libasound2-data</baserpm>
    <baserpm install="yes" arch="all">mysql-common</baserpm>
    <baserpm install="yes" arch="all">libio-socket-ssl-perl</baserpm>
    <baserpm install="yes" arch="all">vim-runtime</baserpm>
    <baserpm install="yes" arch="all">libnet-http-perl</baserpm>
    <baserpm install="yes" arch="all">adwaita-icon-theme</baserpm>
    <baserpm install="yes" arch="all">libyaml-perl</baserpm>
    <baserpm install="yes" arch="all">libxml-sax-perl</baserpm>
    <baserpm install="yes" arch="all">syslinux-common</baserpm>
    <baserpm install="yes" arch="all">libsys-hostname-long-perl</baserpm>
    <baserpm install="yes" arch="all">python3-prettytable</baserpm>
    <baserpm install="yes" arch="all">isolinux</baserpm>
    <baserpm install="yes" arch="all">libalgorithm-diff-perl</baserpm>
    <baserpm install="yes" arch="all">libarchive-cpio-perl</baserpm>
    <baserpm install="yes" arch="all">ieee-data</baserpm>
    <baserpm install="yes" arch="all">debootstrap</baserpm>
    <baserpm install="yes" arch="all">libwww-robotrules-perl</baserpm>
    <baserpm install="yes" arch="all">bsdmainutils</baserpm>
    <baserpm install="yes" arch="all">dpkg-dev</baserpm>
    <baserpm install="yes" arch="all">postgresql</baserpm>
    <baserpm install="yes" arch="all">mecab-ipadic</baserpm>
    <baserpm install="yes" arch="all">libjs-sphinxdoc</baserpm>
    <baserpm install="yes" arch="all">python3-setuptools</baserpm>
    <baserpm install="yes" arch="all">postgresql-client-common</baserpm>
    <baserpm install="yes" arch="all">shorewall-init</baserpm>
    <baserpm install="yes" arch="all">libtypes-serialiser-perl</baserpm>
    <baserpm install="yes" arch="all">python3-blinker</baserpm>
    <baserpm install="yes" arch="all">python3-entrypoints</baserpm>
    <baserpm install="yes" arch="all">libtry-tiny-perl</baserpm>
    <baserpm install="yes" arch="all">python3-secretstorage</baserpm>
    <baserpm install="yes" arch="all">ssl-cert</baserpm>
    <baserpm install="yes" arch="all">libio-html-perl</baserpm>
    <baserpm install="yes" arch="all">python3-netaddr</baserpm>
    <baserpm install="yes" arch="all">quilt</baserpm>
    <baserpm install="yes" arch="all">python3-ply</baserpm>
    <baserpm install="yes" arch="all">screen-resolution-extra</baserpm>
    <baserpm install="yes" arch="all">libsub-override-perl</baserpm>
    <baserpm install="yes" arch="all">libhttp-message-perl</baserpm>
    <baserpm install="yes" arch="all">python3-bs4</baserpm>
    <baserpm install="yes" arch="all">libsoup2.4-common</baserpm>
    <baserpm install="yes" arch="all">debhelper</baserpm>
    <baserpm install="yes" arch="all">java-common</baserpm>
    <baserpm install="yes" arch="all">nslcd-utils</baserpm>
    <baserpm install="yes" arch="all">libjson-glib-1.0-common</baserpm>
    <baserpm install="yes" arch="all">xserver-common</baserpm>
    <baserpm install="yes" arch="all">python3-contextlib2</baserpm>
    <baserpm install="yes" arch="all">python3-wheel</baserpm>
    <baserpm install="yes" arch="all">manpages-dev</baserpm>
    <baserpm install="yes" arch="all">lto-disabled-list</baserpm>
    <baserpm install="yes" arch="all">libhttp-cookies-perl</baserpm>
    <baserpm install="yes" arch="all">mysql-server</baserpm>
    <baserpm install="yes" arch="all">python3-certifi</baserpm>
    <baserpm install="yes" arch="all">python-apt-common</baserpm>
    <baserpm install="no" hwvendor="hp" arch="all">python3-hpilo</baserpm>
    <baserpm install="yes" arch="all">libhtml-tagset-perl</baserpm>
    <baserpm install="yes" arch="all">humanity-icon-theme</baserpm>
    <baserpm install="yes" arch="all">hicolor-icon-theme</baserpm>
    <baserpm install="yes" arch="all">autotools-dev</baserpm>
    <baserpm install="yes" arch="all">sntp</baserpm>
    <baserpm install="yes" arch="all">aptitude-common</baserpm>
    <baserpm install="yes" arch="all">libgdk-pixbuf2.0-common</baserpm>
    <baserpm install="yes" arch="all">python3-zipp</baserpm>
    <baserpm install="yes" arch="all">shorewall6</baserpm>
    <baserpm install="yes" arch="all">mailcap</baserpm>
    <baserpm install="yes" arch="all">intltool</baserpm>
    <baserpm install="yes" arch="all">libcgi-pm-perl</baserpm>
    <baserpm install="yes" arch="all">dns-root-data</baserpm>
    <baserpm install="yes" arch="all">libwww-perl</baserpm>
    <baserpm install="yes" arch="all">python3-xkit</baserpm>
    <baserpm install="yes" arch="all">language-pack-en-base</baserpm>
    <baserpm install="yes" arch="all">libtimedate-perl</baserpm>
    <baserpm install="yes" arch="all">libmail-sendmail-perl</baserpm>
    <baserpm install="yes" arch="all">libgtk2.0-common</baserpm>
    <baserpm install="yes" arch="all">dkms</baserpm>
    <baserpm install="yes" arch="all">libjs-underscore</baserpm>
    <baserpm install="yes" arch="all">libthai-data</baserpm>
    <baserpm install="yes" arch="all">libdebuginfod-common</baserpm>
    <baserpm install="yes" arch="all">libjs-jquery</baserpm>
    <baserpm install="yes" arch="all">libfont-afm-perl</baserpm>
    <baserpm install="yes" arch="all">fonts-dejavu-extra</baserpm>
    <baserpm install="yes" arch="all">x11-common</baserpm>
    <baserpm install="yes" arch="all">libtool</baserpm>
    <baserpm install="yes" arch="all">libgtk-3-common</baserpm>
    <baserpm install="yes" arch="all">language-pack-en</baserpm>
    <baserpm install="yes" arch="all">python3-wcwidth</baserpm>
    <baserpm install="yes" arch="all">libdpkg-perl</baserpm>
    <baserpm install="yes" arch="all">python3-keyring</baserpm>
    <baserpm install="yes" arch="all">automake</baserpm>
    <baserpm install="yes" arch="all">fonts-dejavu-core</baserpm>
    <baserpm install="yes" arch="all">intltool-debian</baserpm>
    <baserpm install="yes" arch="all">python3-more-itertools</baserpm>
    <baserpm install="yes" arch="all">postgresql-common</baserpm>
    <baserpm install="yes" arch="all">libhtml-tree-perl</baserpm>
    <baserpm install="yes" arch="all">libsoup-3.0-common</baserpm>
    <baserpm install="yes" arch="all">libapache2-mod-php</baserpm>
    <baserpm install="yes" arch="all">libhtml-form-perl</baserpm>
    <baserpm install="yes" arch="all">php-common</baserpm>
    <baserpm install="yes" arch="all">ca-certificates-java</baserpm>
    <baserpm install="yes" arch="all">postgresql-contrib</baserpm>
    <baserpm install="yes" arch="all">libsnmp-base</baserpm>
    <baserpm install="yes" arch="all">ubuntu-mono</baserpm>
    <baserpm install="yes" arch="all">autoconf</baserpm>
    <baserpm install="yes" arch="amd64">python3-ntp</baserpm>
    <baserpm install="yes" arch="amd64">libapache2-mod-php8.3</baserpm>
    <baserpm install="yes" arch="amd64">postfix</baserpm>
    <baserpm install="yes" arch="amd64">libllvm17t64</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-render0</baserpm>
    <baserpm install="yes" arch="amd64">libpython3.12-dev</baserpm>
    <baserpm install="yes" arch="amd64">nscd</baserpm>
    <baserpm install="yes" arch="amd64">attr</baserpm>
    <baserpm install="yes" arch="amd64">grub-efi-amd64-bin</baserpm>
    <baserpm install="yes" arch="amd64">rpm2cpio</baserpm>
    <baserpm install="yes" arch="amd64">libgssglue1</baserpm>
    <baserpm install="yes" arch="amd64">libpango-1.0-0</baserpm>
    <baserpm install="yes" arch="amd64">libgcc-11-dev</baserpm>
    <baserpm install="yes" arch="amd64">libharfbuzz0b</baserpm>
    <baserpm install="yes" arch="amd64">libdatrie1</baserpm>
    <baserpm install="yes" arch="amd64">libnss-systemd</baserpm>
    <baserpm install="yes" arch="amd64">libnss-mymachines</baserpm>
    <baserpm install="yes" arch="amd64">libasyncns0</baserpm>
    <baserpm install="yes" arch="amd64">zstd</baserpm>
    <baserpm install="yes" arch="amd64">libllvm19</baserpm>
    <baserpm install="yes" arch="amd64">strace</baserpm>
    <baserpm install="yes" arch="amd64">libsqlite3-0</baserpm>
    <baserpm install="yes" arch="amd64">liblcms2-2</baserpm>
    <baserpm install="yes" arch="amd64">libsystemd0</baserpm>
    <baserpm install="yes" arch="amd64">ntpsec</baserpm>
    <baserpm install="yes" arch="amd64">libboost-system1.83.0</baserpm>
    <baserpm install="yes" arch="amd64">isc-dhcp-client</baserpm>
    <baserpm install="yes" arch="amd64">libpcsclite1</baserpm>
    <baserpm install="yes" arch="amd64">build-essential</baserpm>
    <baserpm install="yes" arch="amd64">libboost-iostreams1.83.0</baserpm>
    <baserpm install="yes" arch="amd64">cpp-11</baserpm>
    <baserpm install="yes" arch="amd64">libpathplan4</baserpm>
    <baserpm install="yes" arch="amd64">man-db</baserpm>
    <baserpm install="yes" arch="amd64">tcl8.6</baserpm>
    <baserpm install="yes" arch="amd64">libhwasan0</baserpm>
    <baserpm install="yes" arch="amd64">tcl</baserpm>
    <baserpm install="yes" arch="amd64">dosfstools</baserpm>
    <baserpm install="yes" arch="amd64">libnl-route-3-dev</baserpm>
    <baserpm install="yes" arch="amd64">libpython3-dev</baserpm>
    <baserpm install="yes" arch="amd64">libzstd-dev</baserpm>
    <baserpm install="yes" arch="amd64">mysql-server-core-8.0</baserpm>
    <baserpm install="yes" arch="amd64">syslinux-utils</baserpm>
    <baserpm install="yes" arch="amd64">sysstat</baserpm>
    <baserpm install="yes" arch="amd64">efivar</baserpm>
    <baserpm install="yes" arch="amd64">libjq1</baserpm>
    <baserpm install="yes" arch="amd64">libegl1</baserpm>
    <baserpm install="yes" arch="amd64">libdb5.3t64</baserpm>
    <baserpm install="yes" arch="amd64">g++-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">libctf0</baserpm>
    <baserpm install="yes" arch="amd64">libdrm-amdgpu1</baserpm>
    <baserpm install="yes" arch="amd64">python3-coverage</baserpm>
    <baserpm install="yes" arch="amd64">libkyotocabinet16v5</baserpm>
    <baserpm install="yes" arch="amd64">libsndfile1</baserpm>
    <baserpm install="yes" arch="amd64">libxpm4</baserpm>
    <baserpm install="yes" arch="amd64">dapl2-utils</baserpm>
    <baserpm install="yes" arch="amd64">pigz</baserpm>
    <baserpm install="yes" arch="amd64">libgdk-pixbuf2.0-0</baserpm>
    <baserpm install="yes" arch="amd64">libxcvt0</baserpm>
    <baserpm install="yes" arch="amd64">libpkgconf3</baserpm>
    <baserpm install="yes" arch="amd64">sshpass</baserpm>
    <baserpm install="yes" arch="amd64">libipsec-mb1</baserpm>
    <baserpm install="yes" arch="amd64">libefiboot1t64</baserpm>
    <baserpm install="yes" arch="amd64">libsm6</baserpm>
    <baserpm install="yes" arch="amd64">python3.12</baserpm>
    <baserpm install="yes" arch="amd64">libgbm1</baserpm>
    <baserpm install="yes" arch="amd64">libjansson4</baserpm>
    <baserpm install="yes" arch="amd64">g++-11</baserpm>
    <baserpm install="yes" arch="amd64">liblua5.2-0</baserpm>
    <baserpm install="yes" arch="amd64">libgles2</baserpm>
    <baserpm install="yes" arch="amd64">libmecab2</baserpm>
    <baserpm install="yes" arch="amd64">syslinux</baserpm>
    <baserpm install="yes" arch="amd64">libxft2</baserpm>
    <baserpm install="yes" arch="amd64">libibverbs1</baserpm>
    <baserpm install="yes" arch="amd64">libssh2-1t64</baserpm>
    <baserpm install="yes" arch="amd64">libumad2sim0</baserpm>
    <baserpm install="yes" arch="amd64">libdrm-intel1</baserpm>
    <baserpm install="yes" arch="amd64">zip</baserpm>
    <baserpm install="yes" arch="amd64">glib-networking-services</baserpm>
    <baserpm install="yes" arch="amd64">nfs-kernel-server</baserpm>
    <baserpm install="yes" arch="amd64">libnss-ldapd</baserpm>
    <baserpm install="yes" arch="amd64">libasprintf-dev</baserpm>
    <baserpm install="yes" arch="amd64">libibmad5</baserpm>
    <baserpm install="yes" arch="amd64">lua-filesystem</baserpm>
    <baserpm install="yes" arch="amd64">python3-cffi-backend</baserpm>
    <baserpm install="yes" arch="amd64">python3-dbus</baserpm>
    <baserpm install="yes" arch="amd64">apache2-utils</baserpm>
    <baserpm install="yes" arch="amd64">fdupes</baserpm>
    <baserpm install="yes" arch="amd64">libsource-highlight4t64</baserpm>
    <baserpm install="yes" arch="amd64">xsltproc</baserpm>
    <baserpm install="yes" arch="amd64">librpmsign9t64</baserpm>
    <baserpm install="yes" arch="amd64">openssh-server</baserpm>
    <baserpm install="yes" arch="amd64">libzstd1</baserpm>
    <baserpm install="yes" arch="amd64">libalgorithm-diff-xs-perl</baserpm>
    <baserpm install="yes" arch="amd64">postgresql-client-16</baserpm>
    <baserpm install="yes" arch="amd64">libnl-route-3-200</baserpm>
    <baserpm install="yes" arch="amd64">lldpd</baserpm>
    <baserpm install="yes" arch="amd64">libxinerama1</baserpm>
    <baserpm install="yes" arch="amd64">libdrm-radeon1</baserpm>
    <baserpm install="yes" arch="amd64">libxss1</baserpm>
    <baserpm install="yes" arch="amd64">php8.3-common</baserpm>
    <baserpm install="yes" arch="amd64">pv</baserpm>
    <baserpm install="yes" arch="amd64">tcl-expect</baserpm>
    <baserpm install="yes" arch="amd64">libpangoft2-1.0-0</baserpm>
    <baserpm install="yes" arch="amd64">xfonts-utils</baserpm>
    <baserpm install="yes" arch="amd64">libxkbcommon-x11-0</baserpm>
    <baserpm install="yes" arch="amd64">librpmio9t64</baserpm>
    <baserpm install="yes" arch="amd64">libipt2</baserpm>
    <baserpm install="yes" arch="amd64">libx11-xcb1</baserpm>
    <baserpm install="yes" arch="amd64">g++-13</baserpm>
    <baserpm install="yes" arch="amd64">gcc-9-base</baserpm>
    <baserpm install="yes" arch="amd64">libfsverity0</baserpm>
    <baserpm install="yes" arch="amd64">binfmt-support</baserpm>
    <baserpm install="yes" arch="amd64">libopts25</baserpm>
    <baserpm install="yes" arch="amd64">libgtk2.0-bin</baserpm>
    <baserpm install="yes" arch="amd64">libtsan2</baserpm>
    <baserpm install="yes" arch="amd64">ibsim-utils</baserpm>
    <baserpm install="yes" arch="amd64">libgtk-3-bin</baserpm>
    <baserpm install="yes" arch="amd64">rdma-core</baserpm>
    <baserpm install="yes" arch="amd64">g++-9</baserpm>
    <baserpm install="yes" arch="amd64">subversion</baserpm>
    <baserpm install="yes" arch="amd64">groff-base</baserpm>
    <baserpm install="yes" arch="amd64">cpp</baserpm>
    <baserpm install="yes" arch="amd64">libltdl7</baserpm>
    <baserpm install="yes" arch="amd64">apache2-bin</baserpm>
    <baserpm install="yes" arch="amd64">ntpsec-ntpdate</baserpm>
    <baserpm install="yes" arch="amd64">libavahi-common-data</baserpm>
    <baserpm install="yes" arch="amd64">session-migration</baserpm>
    <baserpm install="yes" arch="amd64">postgresql-16</baserpm>
    <baserpm install="yes" arch="amd64">libfontenc1</baserpm>
    <baserpm install="yes" arch="amd64">libxtst6</baserpm>
    <baserpm install="yes" arch="amd64">ibacm</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-shm0</baserpm>
    <baserpm install="yes" arch="amd64">libpcre2-32-0</baserpm>
    <baserpm install="yes" arch="amd64">libglvnd0</baserpm>
    <baserpm install="yes" arch="amd64">libthai0</baserpm>
    <baserpm install="yes" arch="amd64">libical3t64</baserpm>
    <baserpm install="yes" arch="amd64">libdconf1</baserpm>
    <baserpm install="yes" arch="amd64">g++</baserpm>
    <baserpm install="yes" arch="amd64">libgettextpo-dev</baserpm>
    <baserpm install="yes" arch="amd64">lua5.1</baserpm>
    <baserpm install="yes" arch="amd64">libxt6t64</baserpm>
    <baserpm install="yes" arch="amd64">libxfont2</baserpm>
    <baserpm install="yes" arch="amd64">libsocket6-perl</baserpm>
    <baserpm install="yes" arch="amd64">thin-provisioning-tools</baserpm>
    <baserpm install="yes" arch="amd64">efibootmgr</baserpm>
    <baserpm install="yes" arch="amd64">bzip2</baserpm>
    <baserpm install="yes" arch="amd64">libsodium23</baserpm>
    <baserpm install="yes" arch="amd64">php8.3-readline</baserpm>
    <baserpm install="yes" arch="amd64">cgroup-tools</baserpm>
    <baserpm install="yes" arch="amd64">libxdamage1</baserpm>
    <baserpm install="yes" arch="amd64">snmptrapd</baserpm>
    <baserpm install="yes" arch="amd64">libasan6</baserpm>
    <baserpm install="yes" arch="amd64">python3-libxml2</baserpm>
    <baserpm install="yes" arch="amd64">lua-posix</baserpm>
    <baserpm install="yes" arch="amd64">xcvt</baserpm>
    <baserpm install="yes" arch="amd64">libntlm0</baserpm>
    <baserpm install="yes" arch="amd64">gfortran-9</baserpm>
    <baserpm install="yes" arch="amd64">nslcd</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-dri3-0</baserpm>
    <baserpm install="yes" arch="amd64">libquadmath0</baserpm>
    <baserpm install="yes" arch="amd64">cpp-13-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">libfcgi-bin</baserpm>
    <baserpm install="yes" arch="amd64">libsnmp40t64</baserpm>
    <baserpm install="yes" arch="amd64">python3-rpm</baserpm>
    <baserpm install="yes" arch="amd64">patchutils</baserpm>
    <baserpm install="yes" arch="amd64">libxv1</baserpm>
    <baserpm install="yes" arch="amd64">libcgraph6</baserpm>
    <baserpm install="yes" arch="amd64">libnsl-dev</baserpm>
    <baserpm install="yes" arch="amd64">cpp-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">guile-3.0-libs</baserpm>
    <baserpm install="yes" arch="amd64">librdmacm1t64</baserpm>
    <baserpm install="yes" arch="amd64">libc6-dev</baserpm>
    <baserpm install="yes" arch="amd64">libtirpc3t64</baserpm>
    <baserpm install="yes" arch="amd64">libstdc++-9-dev</baserpm>
    <baserpm install="yes" arch="amd64">libnl-3-dev</baserpm>
    <baserpm install="yes" arch="amd64">dialog</baserpm>
    <baserpm install="yes" arch="amd64">libcommon-sense-perl</baserpm>
    <baserpm install="yes" arch="amd64">libsigc++-2.0-0v5</baserpm>
    <baserpm install="yes" arch="amd64">aptitude</baserpm>
    <baserpm install="yes" arch="amd64">gfortran</baserpm>
    <baserpm install="yes" arch="amd64">libgcc-12-dev</baserpm>
    <baserpm install="yes" arch="amd64">libevent-pthreads-2.1-7t64</baserpm>
    <baserpm install="yes" arch="amd64">libunistring5</baserpm>
    <baserpm install="yes" arch="amd64">pkgconf</baserpm>
    <baserpm install="yes" arch="amd64">expect</baserpm>
    <baserpm install="yes" arch="amd64">libwayland-cursor0</baserpm>
    <baserpm install="yes" arch="amd64">isc-dhcp-common</baserpm>
    <baserpm install="yes" arch="amd64">libfakeroot</baserpm>
    <baserpm install="yes" arch="amd64">libpsm-infinipath1</baserpm>
    <baserpm install="yes" arch="amd64">libboost-regex1.83.0</baserpm>
    <baserpm install="yes" arch="amd64">libjson-xs-perl</baserpm>
    <baserpm install="yes" arch="amd64">libjpeg-turbo8</baserpm>
    <baserpm install="yes" arch="amd64">libgvc6</baserpm>
    <baserpm install="yes" arch="amd64">gfortran-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">libgts-bin</baserpm>
    <baserpm install="yes" arch="amd64">dconf-service</baserpm>
    <baserpm install="yes" arch="amd64">libpciaccess0</baserpm>
    <baserpm install="yes" arch="amd64">libatk1.0-0t64</baserpm>
    <baserpm install="yes" arch="amd64">libyaml-0-2</baserpm>
    <baserpm install="yes" arch="amd64">libglx-mesa0</baserpm>
    <baserpm install="yes" arch="amd64">xterm</baserpm>
    <baserpm install="yes" arch="amd64">libflac12t64</baserpm>
    <baserpm install="yes" arch="amd64">libevent-2.1-7t64</baserpm>
    <baserpm install="yes" arch="amd64">libibdm1</baserpm>
    <baserpm install="yes" arch="amd64">libpam-systemd</baserpm>
    <baserpm install="yes" arch="amd64">libogg0</baserpm>
    <baserpm install="yes" arch="amd64">libfontconfig1</baserpm>
    <baserpm install="yes" arch="amd64">libdbd-mysql-perl</baserpm>
    <baserpm install="yes" arch="amd64">linux-firmware</baserpm>
    <baserpm install="yes" arch="amd64">bind9-dnsutils</baserpm>
    <baserpm install="yes" arch="amd64">libfile-fcntllock-perl</baserpm>
    <baserpm install="yes" arch="amd64">libtdb1</baserpm>
    <baserpm install="yes" arch="amd64">jq</baserpm>
    <baserpm install="yes" arch="amd64">libgail-common</baserpm>
    <baserpm install="yes" arch="amd64">python3.12-dev</baserpm>
    <baserpm install="yes" arch="amd64">libclone-perl</baserpm>
    <baserpm install="yes" arch="amd64">keyutils</baserpm>
    <baserpm install="yes" arch="amd64">libgprofng0</baserpm>
    <baserpm install="yes" arch="amd64">liblua5.1-0</baserpm>
    <baserpm install="yes" arch="amd64">libhtml-parser-perl</baserpm>
    <baserpm install="yes" arch="amd64">grub2-common</baserpm>
    <baserpm install="yes" arch="amd64">libaio1t64</baserpm>
    <baserpm install="yes" arch="amd64">libblas3</baserpm>
    <baserpm install="yes" arch="amd64">libcrypt-dev</baserpm>
    <baserpm install="yes" arch="amd64">libpython3.12-minimal</baserpm>
    <baserpm install="yes" arch="amd64">libopus0</baserpm>
    <baserpm install="yes" arch="amd64">libvdpau1</baserpm>
    <baserpm install="yes" arch="amd64">psmisc</baserpm>
    <baserpm install="yes" arch="amd64">libepoxy0</baserpm>
    <baserpm install="yes" arch="amd64">liblua5.4-0</baserpm>
    <baserpm install="yes" arch="amd64">ifupdown</baserpm>
    <baserpm install="yes" arch="amd64">libmuparser2v5</baserpm>
    <baserpm install="yes" arch="amd64">libonig5</baserpm>
    <baserpm install="yes" arch="amd64">libsctp1</baserpm>
    <baserpm install="yes" arch="amd64">libboost-filesystem1.83.0</baserpm>
    <baserpm install="yes" arch="amd64">libcups2t64</baserpm>
    <baserpm install="yes" arch="amd64">libxshmfence1</baserpm>
    <baserpm install="yes" arch="amd64">libxrandr2</baserpm>
    <baserpm install="yes" arch="amd64">libatomic1</baserpm>
    <baserpm install="yes" arch="amd64">dwz</baserpm>
    <baserpm install="yes" arch="amd64">tcpdump</baserpm>
    <baserpm install="yes" arch="amd64">pkexec</baserpm>
    <baserpm install="yes" arch="amd64">libmailutils9t64</baserpm>
    <baserpm install="yes" arch="amd64">libgts-0.7-5t64</baserpm>
    <baserpm install="yes" arch="amd64">socat</baserpm>
    <baserpm install="yes" arch="amd64">libc6-dbg</baserpm>
    <baserpm install="yes" arch="amd64">libgtk-3-0t64</baserpm>
    <baserpm install="yes" arch="amd64">libnfsidmap1</baserpm>
    <baserpm install="yes" arch="amd64">libtk8.6</baserpm>
    <baserpm install="yes" arch="amd64">rpm</baserpm>
    <baserpm install="yes" arch="amd64">libc-devtools</baserpm>
    <baserpm install="yes" arch="amd64">libxxhash0</baserpm>
    <baserpm install="yes" arch="amd64">infiniband-diags</baserpm>
    <baserpm install="yes" arch="amd64">liblsan0</baserpm>
    <baserpm install="yes" arch="amd64">ibutils</baserpm>
    <baserpm install="yes" arch="amd64">libgdk-pixbuf-2.0-0</baserpm>
    <baserpm install="yes" arch="amd64">ed</baserpm>
    <baserpm install="yes" arch="amd64">libidn12</baserpm>
    <baserpm install="yes" arch="amd64">libnuma1</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-shape0</baserpm>
    <baserpm install="yes" arch="amd64">libasound2t64</baserpm>
    <baserpm install="yes" arch="amd64">ncal</baserpm>
    <baserpm install="yes" arch="amd64">xorriso</baserpm>
    <baserpm install="yes" arch="amd64">libfl2</baserpm>
    <baserpm install="yes" arch="amd64">lua-bitop</baserpm>
    <baserpm install="yes" arch="amd64">smartmontools</baserpm>
    <baserpm install="yes" arch="amd64">cpp-12</baserpm>
    <baserpm install="yes" arch="amd64">libwayland-egl1</baserpm>
    <baserpm install="yes" arch="amd64">libpixman-1-0</baserpm>
    <baserpm install="yes" arch="amd64">libgenders0</baserpm>
    <baserpm install="yes" arch="amd64">debugedit</baserpm>
    <baserpm install="yes" arch="amd64">libgraphite2-3</baserpm>
    <baserpm install="yes" arch="amd64">snmpd</baserpm>
    <baserpm install="yes" arch="amd64">libsub-name-perl</baserpm>
    <baserpm install="yes" arch="amd64">libavahi-glib1</baserpm>
    <baserpm install="yes" arch="amd64">libxi6</baserpm>
    <baserpm install="yes" arch="amd64">libc-dev-bin</baserpm>
    <baserpm install="yes" arch="amd64">mailutils</baserpm>
    <baserpm install="yes" arch="amd64">stress-ng</baserpm>
    <baserpm install="yes" arch="amd64">fontconfig-config</baserpm>
    <baserpm install="yes" arch="amd64">plocate</baserpm>
    <baserpm install="yes" arch="amd64">python3-psutil</baserpm>
    <baserpm install="yes" arch="amd64">perftest</baserpm>
    <baserpm install="yes" arch="amd64">libstdc++-13-dev</baserpm>
    <baserpm install="yes" arch="amd64">libubsan1</baserpm>
    <baserpm install="yes" arch="amd64">apache2</baserpm>
    <baserpm install="yes" arch="amd64">gcc-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">fakeroot</baserpm>
    <baserpm install="yes" arch="amd64">gcc-12-base</baserpm>
    <baserpm install="yes" arch="amd64">librest-1.0-0</baserpm>
    <baserpm install="yes" arch="amd64">vdpau-driver-all</baserpm>
    <baserpm install="yes" arch="amd64">libbinutils</baserpm>
    <baserpm install="yes" arch="amd64">libsensors5</baserpm>
    <baserpm install="yes" arch="amd64">libsframe1</baserpm>
    <baserpm install="yes" arch="amd64">libfuse2t64</baserpm>
    <baserpm install="yes" arch="amd64">libaprutil1t64</baserpm>
    <baserpm install="yes" arch="amd64">grub-common</baserpm>
    <baserpm install="yes" arch="amd64">python3</baserpm>
    <baserpm install="yes" arch="amd64">iputils-arping</baserpm>
    <baserpm install="yes" arch="amd64">zlib1g-dev</baserpm>
    <baserpm install="yes" arch="amd64">srptools</baserpm>
    <baserpm install="yes" arch="amd64">libpq5</baserpm>
    <baserpm install="yes" arch="amd64">libgd3</baserpm>
    <baserpm install="yes" arch="amd64">libibnetdisc5t64</baserpm>
    <baserpm install="yes" arch="amd64">libcanberra0t64</baserpm>
    <baserpm install="yes" arch="amd64">csh</baserpm>
    <baserpm install="yes" arch="amd64">python3-yaml</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-present0</baserpm>
    <baserpm install="yes" arch="amd64">python3-pycurl</baserpm>
    <baserpm install="yes" arch="amd64">rpm-common</baserpm>
    <baserpm install="yes" arch="amd64">libavahi-client3</baserpm>
    <baserpm install="yes" arch="amd64">gcc-13-base</baserpm>
    <baserpm install="yes" arch="amd64">grub-efi-amd64</baserpm>
    <baserpm install="yes" arch="amd64">libefivar1t64</baserpm>
    <baserpm install="yes" arch="amd64">libice6</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-glx0</baserpm>
    <baserpm install="yes" arch="amd64">libwayland-client0</baserpm>
    <baserpm install="yes" arch="amd64">libpipeline1</baserpm>
    <baserpm install="yes" arch="amd64">libxkbfile1</baserpm>
    <baserpm install="yes" arch="amd64">nfs-common</baserpm>
    <baserpm install="yes" arch="amd64">fontconfig</baserpm>
    <baserpm install="yes" arch="amd64">libxapian30</baserpm>
    <baserpm install="yes" arch="amd64">libnsl2</baserpm>
    <baserpm install="yes" arch="amd64">libwayland-server0</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-randr0</baserpm>
    <baserpm install="yes" arch="amd64">libvorbisfile3</baserpm>
    <baserpm install="yes" arch="amd64">libgomp1</baserpm>
    <baserpm install="yes" arch="amd64">mesa-vdpau-drivers</baserpm>
    <baserpm install="yes" arch="amd64">libjudydebian1</baserpm>
    <baserpm install="yes" arch="amd64">lua-bit32</baserpm>
    <baserpm install="yes" arch="amd64">libefisec1t64</baserpm>
    <baserpm install="yes" arch="amd64">libterm-readkey-perl</baserpm>
    <baserpm install="yes" arch="amd64">libopensm9</baserpm>
    <baserpm install="yes" arch="amd64">libfcgi0t64</baserpm>
    <baserpm install="yes" arch="amd64">gettext</baserpm>
    <baserpm install="yes" arch="amd64">net-tools</baserpm>
    <baserpm install="yes" arch="amd64">htop</baserpm>
    <baserpm install="yes" arch="amd64">libcwidget4</baserpm>
    <baserpm install="yes" arch="amd64">parted</baserpm>
    <baserpm install="yes" arch="amd64">libgl1</baserpm>
    <baserpm install="yes" arch="amd64">libsoup-2.4-1</baserpm>
    <baserpm install="yes" arch="amd64">systemd-sysv</baserpm>
    <baserpm install="yes" arch="amd64">libfl-dev</baserpm>
    <baserpm install="yes" arch="amd64">swig4.1</baserpm>
    <baserpm install="yes" arch="amd64">libmpc3</baserpm>
    <baserpm install="yes" arch="amd64">librpm9t64</baserpm>
    <baserpm install="yes" arch="amd64">openjdk-8-jre</baserpm>
    <baserpm install="yes" arch="amd64">libjpeg8</baserpm>
    <baserpm install="yes" arch="amd64">vim</baserpm>
    <baserpm install="yes" arch="amd64">systemd</baserpm>
    <baserpm install="yes" arch="amd64">libevent-core-2.1-7t64</baserpm>
    <baserpm install="yes" arch="amd64">libpangocairo-1.0-0</baserpm>
    <baserpm install="yes" arch="amd64">cryptsetup</baserpm>
    <baserpm install="yes" arch="amd64">genisoimage</baserpm>
    <baserpm install="yes" arch="amd64">libgfortran-11-dev</baserpm>
    <baserpm install="yes" arch="amd64">ntpsec-ntpdig</baserpm>
    <baserpm install="yes" arch="amd64">python3-cryptography</baserpm>
    <baserpm install="yes" arch="amd64">libcolord2</baserpm>
    <baserpm install="yes" arch="amd64">gcc-13-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">cpp-9</baserpm>
    <baserpm install="yes" arch="amd64">python3.12-minimal</baserpm>
    <baserpm install="yes" arch="amd64">libegl-mesa0</baserpm>
    <baserpm install="yes" arch="amd64">libibumad3</baserpm>
    <baserpm install="yes" arch="amd64">binutils-common</baserpm>
    <baserpm install="yes" arch="amd64">opensm</baserpm>
    <baserpm install="yes" arch="amd64">systemd-container</baserpm>
    <baserpm install="yes" arch="amd64">libnetfilter-cthelper0</baserpm>
    <baserpm install="yes" arch="amd64">libmp3lame0</baserpm>
    <baserpm install="yes" arch="amd64">libproxy1v5</baserpm>
    <baserpm install="yes" arch="amd64">dbus-x11</baserpm>
    <baserpm install="yes" arch="amd64">libdeflate0</baserpm>
    <baserpm install="yes" arch="amd64">libsoup-gnome-2.4-1</baserpm>
    <baserpm install="yes" arch="amd64">libllvm18</baserpm>
    <baserpm install="yes" arch="amd64">pkgconf-bin</baserpm>
    <baserpm install="yes" arch="amd64">chrpath</baserpm>
    <baserpm install="yes" arch="amd64">libgcc-13-dev</baserpm>
    <baserpm install="yes" arch="amd64">mtools</baserpm>
    <baserpm install="yes" arch="amd64">grub-pc-bin</baserpm>
    <baserpm install="yes" arch="amd64">libpulse0</baserpm>
    <baserpm install="yes" arch="amd64">libbabeltrace1</baserpm>
    <baserpm install="yes" arch="amd64">libctf-nobfd0</baserpm>
    <baserpm install="yes" arch="amd64">libmpg123-0t64</baserpm>
    <baserpm install="yes" arch="amd64">gcc</baserpm>
    <baserpm install="yes" arch="amd64">g++-13-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">gcc-9</baserpm>
    <baserpm install="yes" arch="amd64">binutils</baserpm>
    <baserpm install="yes" arch="amd64">libltdl-dev</baserpm>
    <baserpm install="yes" arch="amd64">python3-dev</baserpm>
    <baserpm install="yes" arch="amd64">binutils-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">libssl-dev</baserpm>
    <baserpm install="yes" arch="amd64">libnspr4</baserpm>
    <baserpm install="yes" arch="amd64">libnetsnmptrapd40t64</baserpm>
    <baserpm install="yes" arch="amd64">libwebp7</baserpm>
    <baserpm install="yes" arch="amd64">libexpat1-dev</baserpm>
    <baserpm install="yes" arch="amd64">libisofs6t64</baserpm>
    <baserpm install="yes" arch="amd64">libxml-libxml-perl</baserpm>
    <baserpm install="yes" arch="amd64">libcairo2</baserpm>
    <baserpm install="yes" arch="amd64">libgfortran5</baserpm>
    <baserpm install="yes" arch="amd64">mysql-server-8.0</baserpm>
    <baserpm install="yes" arch="amd64">libvpx9</baserpm>
    <baserpm install="yes" arch="amd64">libxmu6</baserpm>
    <baserpm install="yes" arch="amd64">gcc-11-base</baserpm>
    <baserpm install="yes" arch="amd64">libatk-bridge2.0-0t64</baserpm>
    <baserpm install="yes" arch="amd64">bind9-host</baserpm>
    <baserpm install="yes" arch="amd64">libgsasl18</baserpm>
    <baserpm install="yes" arch="amd64">gtk-update-icon-cache</baserpm>
    <baserpm install="yes" arch="amd64">libparted2t64</baserpm>
    <baserpm install="yes" arch="amd64">libbison-dev</baserpm>
    <baserpm install="yes" arch="amd64">rdmacm-utils</baserpm>
    <baserpm install="yes" arch="amd64">libtcl8.6</baserpm>
    <baserpm install="yes" arch="amd64">libdapl2</baserpm>
    <baserpm install="yes" arch="amd64">libcc1-0</baserpm>
    <baserpm install="yes" arch="amd64">libelf1t64</baserpm>
    <baserpm install="yes" arch="amd64">cryptsetup-bin</baserpm>
    <baserpm install="yes" arch="amd64">make</baserpm>
    <baserpm install="yes" arch="amd64">unzip</baserpm>
    <baserpm install="yes" arch="amd64">libgl1-amber-dri</baserpm>
    <baserpm install="yes" arch="amd64">libxslt1.1</baserpm>
    <baserpm install="yes" arch="amd64">libapr1t64</baserpm>
    <baserpm install="yes" arch="amd64">librpmbuild9t64</baserpm>
    <baserpm install="yes" arch="amd64">xserver-xorg-core</baserpm>
    <baserpm install="yes" arch="amd64">libtirpc-dev</baserpm>
    <baserpm install="yes" arch="amd64">bison</baserpm>
    <baserpm install="yes" arch="amd64">libxrender1</baserpm>
    <baserpm install="yes" arch="amd64">libstdc++-11-dev</baserpm>
    <baserpm install="yes" arch="amd64">linux-libc-dev</baserpm>
    <baserpm install="yes" arch="amd64">mysql-client-core-8.0</baserpm>
    <baserpm install="yes" arch="amd64">switcheroo-control</baserpm>
    <baserpm install="yes" arch="amd64">libpsm-infinipath1-dev</baserpm>
    <baserpm install="yes" arch="amd64">libibmad-dev</baserpm>
    <baserpm install="yes" arch="amd64">squashfs-tools</baserpm>
    <baserpm install="yes" arch="amd64">libgfortran-13-dev</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-dri2-0</baserpm>
    <baserpm install="yes" arch="amd64">tk8.6</baserpm>
    <baserpm install="yes" arch="amd64">libgc1</baserpm>
    <baserpm install="yes" arch="amd64">liburing2</baserpm>
    <baserpm install="yes" arch="amd64">libasan5</baserpm>
    <baserpm install="yes" arch="amd64">pkg-config</baserpm>
    <baserpm install="yes" arch="amd64">libjbig0</baserpm>
    <baserpm install="yes" arch="amd64">libgcc-9-dev</baserpm>
    <baserpm install="yes" arch="amd64">python3-lxml</baserpm>
    <baserpm install="yes" arch="amd64">libjte2t64</baserpm>
    <baserpm install="yes" arch="amd64">libxml2-utils</baserpm>
    <baserpm install="yes" arch="amd64">python3-zstandard</baserpm>
    <baserpm install="yes" arch="amd64">gcc-13</baserpm>
    <baserpm install="yes" arch="amd64">libann0</baserpm>
    <baserpm install="yes" arch="amd64">python3-minimal</baserpm>
    <baserpm install="yes" arch="amd64">gfortran-11</baserpm>
    <baserpm install="yes" arch="amd64">librsvg2-common</baserpm>
    <baserpm install="yes" arch="amd64">lua-lpeg</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-sync1</baserpm>
    <baserpm install="yes" arch="amd64">libglapi-mesa</baserpm>
    <baserpm install="yes" arch="amd64">libcgroup2</baserpm>
    <baserpm install="yes" arch="amd64">libisl23</baserpm>
    <baserpm install="yes" arch="amd64">libxcomposite1</baserpm>
    <baserpm install="yes" arch="amd64">libgif7</baserpm>
    <baserpm install="yes" arch="amd64">libutf8proc3</baserpm>
    <baserpm install="yes" arch="amd64">libgail18t64</baserpm>
    <baserpm install="yes" arch="amd64">libxxf86vm1</baserpm>
    <baserpm install="yes" arch="amd64">systemd-coredump</baserpm>
    <baserpm install="yes" arch="amd64">liblab-gamut1</baserpm>
    <baserpm install="yes" arch="amd64">libarchive13t64</baserpm>
    <baserpm install="yes" arch="amd64">libcryptsetup12</baserpm>
    <baserpm install="yes" arch="amd64">rpcsvc-proto</baserpm>
    <baserpm install="yes" arch="amd64">libsvn1</baserpm>
    <baserpm install="yes" arch="amd64">mesa-vulkan-drivers</baserpm>
    <baserpm install="yes" arch="amd64">diffstat</baserpm>
    <baserpm install="yes" arch="amd64">libatspi2.0-0t64</baserpm>
    <baserpm install="yes" arch="amd64">dconf-gsettings-backend</baserpm>
    <baserpm install="yes" arch="amd64">libglx0</baserpm>
    <baserpm install="yes" arch="amd64">libasprintf0v5</baserpm>
    <baserpm install="yes" arch="amd64">bind9-utils</baserpm>
    <baserpm install="yes" arch="amd64">gdbserver</baserpm>
    <baserpm install="yes" arch="amd64">libsoup-3.0-0</baserpm>
    <baserpm install="yes" arch="amd64">mysql-client-8.0</baserpm>
    <baserpm install="yes" arch="amd64">php8.3-opcache</baserpm>
    <baserpm install="yes" arch="amd64">nvme-cli</baserpm>
    <baserpm install="yes" arch="amd64">at-spi2-core</baserpm>
    <baserpm install="yes" arch="amd64">libfcgi-perl</baserpm>
    <baserpm install="yes" arch="amd64">openjdk-8-jre-headless</baserpm>
    <baserpm install="yes" arch="amd64">libxcursor1</baserpm>
    <baserpm install="yes" arch="amd64">libatk-wrapper-java-jni</baserpm>
    <baserpm install="yes" arch="amd64">libgdk-pixbuf2.0-bin</baserpm>
    <baserpm install="yes" arch="amd64">mecab-utils</baserpm>
    <baserpm install="yes" arch="amd64">libgeoip1t64</baserpm>
    <baserpm install="yes" arch="amd64">python3-apt</baserpm>
    <baserpm install="yes" arch="amd64">libaprutil1-dbd-sqlite3</baserpm>
    <baserpm install="yes" arch="amd64">gdb</baserpm>
    <baserpm install="yes" arch="amd64">guile-2.2-libs</baserpm>
    <baserpm install="yes" arch="amd64">m4</baserpm>
    <baserpm install="yes" arch="amd64">bc</baserpm>
    <baserpm install="yes" arch="amd64">librsvg2-2</baserpm>
    <baserpm install="yes" arch="amd64">mstflint</baserpm>
    <baserpm install="yes" arch="amd64">libdebuginfod1t64</baserpm>
    <baserpm install="yes" arch="amd64">libjson-glib-1.0-0</baserpm>
    <baserpm install="yes" arch="amd64">libxaw7</baserpm>
    <baserpm install="yes" arch="amd64">libmysqlclient-dev</baserpm>
    <baserpm install="yes" arch="amd64">libitm1</baserpm>
    <baserpm install="yes" arch="amd64">libnss3</baserpm>
    <baserpm install="yes" arch="amd64">libdbi-perl</baserpm>
    <baserpm install="yes" arch="amd64">libibumad-dev</baserpm>
    <baserpm install="yes" arch="amd64">libavahi-common3</baserpm>
    <baserpm install="yes" arch="amd64">libosmcomp5</baserpm>
    <baserpm install="yes" arch="amd64">lsof</baserpm>
    <baserpm install="yes" arch="amd64">python3-gi</baserpm>
    <baserpm install="yes" arch="amd64">libmnl-dev</baserpm>
    <baserpm install="yes" arch="amd64">libasan8</baserpm>
    <baserpm install="yes" arch="amd64">ibverbs-providers</baserpm>
    <baserpm install="yes" arch="amd64">perl-openssl-defaults</baserpm>
    <baserpm install="yes" arch="amd64">swig</baserpm>
    <baserpm install="yes" arch="amd64">glib-networking</baserpm>
    <baserpm install="yes" arch="amd64">tk</baserpm>
    <baserpm install="yes" arch="amd64">libprotobuf-lite32t64</baserpm>
    <baserpm install="yes" arch="amd64">libgettextpo0</baserpm>
    <baserpm install="yes" arch="amd64">libpcap0.8t64</baserpm>
    <baserpm install="yes" arch="amd64">x11-xkb-utils</baserpm>
    <baserpm install="yes" arch="amd64">libosmvendor5</baserpm>
    <baserpm install="yes" arch="amd64">dctrl-tools</baserpm>
    <baserpm install="yes" arch="amd64">libgfortran-9-dev</baserpm>
    <baserpm install="yes" arch="amd64">libgvpr2</baserpm>
    <baserpm install="yes" arch="amd64">bind9</baserpm>
    <baserpm install="yes" arch="amd64">gcc-11</baserpm>
    <baserpm install="yes" arch="amd64">ldap-utils</baserpm>
    <baserpm install="yes" arch="amd64">libpam-ldapd</baserpm>
    <baserpm install="yes" arch="amd64">liblua5.3-0</baserpm>
    <baserpm install="yes" arch="amd64">genders</baserpm>
    <baserpm install="yes" arch="amd64">bridge-utils</baserpm>
    <baserpm install="yes" arch="amd64">libatasmart4</baserpm>
    <baserpm install="yes" arch="amd64">libtiff6</baserpm>
    <baserpm install="yes" arch="amd64">libnuma-dev</baserpm>
    <baserpm install="yes" arch="amd64">libcairo-gobject2</baserpm>
    <baserpm install="yes" arch="amd64">libyaml-libyaml-perl</baserpm>
    <baserpm install="yes" arch="amd64">libxfixes3</baserpm>
    <baserpm install="yes" arch="amd64">libpython3.12-stdlib</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-xkb1</baserpm>
    <baserpm install="yes" arch="amd64">gfortran-13</baserpm>
    <baserpm install="yes" arch="amd64">ibverbs-utils</baserpm>
    <baserpm install="yes" arch="amd64">libjsoncpp25</baserpm>
    <baserpm install="yes" arch="amd64">cpp-13</baserpm>
    <baserpm install="yes" arch="amd64">gcc-12</baserpm>
    <baserpm install="yes" arch="amd64">libtsan0</baserpm>
    <baserpm install="yes" arch="amd64">libmysqlclient21</baserpm>
    <baserpm install="yes" arch="amd64">libserf-1-1</baserpm>
    <baserpm install="yes" arch="amd64">gfortran-13-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">bind9-libs</baserpm>
    <baserpm install="yes" arch="amd64">libdrm-nouveau2</baserpm>
    <baserpm install="yes" arch="amd64">libvorbisenc2</baserpm>
    <baserpm install="yes" arch="amd64">x11-utils</baserpm>
    <baserpm install="yes" arch="amd64">libpython3-stdlib</baserpm>
    <baserpm install="yes" arch="amd64">libgtk2.0-0t64</baserpm>
    <baserpm install="yes" arch="amd64">libxkbcommon0</baserpm>
    <baserpm install="yes" arch="amd64">libisoburn1t64</baserpm>
    <baserpm install="yes" arch="amd64">libburn4t64</baserpm>
    <baserpm install="yes" arch="amd64">libdw1t64</baserpm>
    <baserpm install="yes" arch="amd64">libcdt5</baserpm>
    <baserpm install="yes" arch="amd64">libnet-ssleay-perl</baserpm>
    <baserpm install="yes" arch="amd64">xxhash</baserpm>
    <baserpm install="yes" arch="amd64">libgdk-pixbuf-xlib-2.0-0</baserpm>
    <baserpm install="yes" arch="amd64">libaprutil1-ldap</baserpm>
    <baserpm install="yes" arch="amd64">libvulkan1</baserpm>
    <baserpm install="yes" arch="amd64">graphviz</baserpm>
    <baserpm install="yes" arch="amd64">mesa-libgallium</baserpm>
    <baserpm install="yes" arch="amd64">php8.3-cli</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-xfixes0</baserpm>
    <baserpm install="yes" arch="amd64">libvorbis0a</baserpm>
    <baserpm install="yes" arch="amd64">libgl1-mesa-dri</baserpm>
    <baserpm install="yes" arch="amd64">rpcbind</baserpm>
    <baserpm install="yes" arch="amd64">flex</baserpm>
    <baserpm install="yes" arch="amd64">libxml-parser-perl</baserpm>
    <baserpm install="yes" arch="amd64">libpython3.12t64</baserpm>
    <baserpm install="yes" arch="amd64">libxxf86dga1</baserpm>
    <cmrpm install="yes" arch="all">cm-image</cmrpm>
    <cmrpm install="yes" arch="all">cm-scale</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-grub</cmrpm>
    <cmrpm install="yes" arch="all">cm-master</cmrpm>
    <cmrpm install="yes" arch="all">cm-workload</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-man</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-apt</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-cmsupport-files</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-mysql</cmrpm>
    <cmrpm install="yes" arch="all">cm-webportal</cmrpm>
    <cmrpm install="yes" arch="all">cm-manuals</cmrpm>
    <cmrpm install="yes" arch="all">cm-crontabs-master</cmrpm>
    <cmrpm install="yes" arch="all">cmdaemon-pythoncm</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-systemd-master</cmrpm>
    <cmrpm install="yes" arch="all">cm-modules-init</cmrpm>
    <cmrpm install="yes" arch="all">cm-api-docs</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-ldap-client-master</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-syslog</cmrpm>
    <cmrpm install="yes" arch="all">cm-shorewall-config</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-snmp</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-cm</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-rootfiles</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-ssh</cmrpm>
    <cmrpm install="yes" arch="all">cm-bios-tools</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-sysctl</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-apt-cuda</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-motd</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-dhclient</cmrpm>
    <cmrpm install="yes" arch="all">cm-lite-daemon-dist</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-http-bcm</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-limits</cmrpm>
    <cmrpm install="yes" arch="all">base-view</cmrpm>
    <cmrpm install="yes" arch="all">cm-mysql++-devel</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-nfsserver</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-qemu-user-static</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-busybox</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-rocm-smi</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-luajit</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-sdparm</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-nvssvt</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-freeipmi</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-gcc</cmrpm>
    <cmrpm install="yes" arch="amd64">lmod</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-python312</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-lshw</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-rsync</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-config-os-arch</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-openvpn</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-mpfr</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-openssl</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-tftpboot</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-dhcp</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-curl</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-atftp</cmrpm>
    <cmrpm install="yes" arch="amd64">net-snmp-recent</cmrpm>
    <cmrpm install="yes" arch="amd64">cmburn</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-lua</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-setup</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-mpc</cmrpm>
    <cmrpm install="yes" arch="amd64">lua5.1-tcl2lua</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-installer-rescue</cmrpm>
    <cmrpm install="yes" arch="amd64">cuda-dcgm-libs</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-gmp</cmrpm>
    <cmrpm install="yes" arch="amd64">cmdaemon-remotecm</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-sedutil</cmrpm>
    <cmrpm install="yes" arch="amd64">gdb-recent</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-conman</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-iperf</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-ipmitool</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-nvfwupd</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-libprometheus</cmrpm>
    <cmrpm install="yes" arch="amd64">openldap-servers</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-confuse</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-prs</cmrpm>
    <cmrpm install="yes" arch="amd64">cmdaemon-cmsh</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-modules</cmrpm>
    <cmrpm install="yes" arch="amd64">cluster-tools</cmrpm>
    <cmrpm install="yes" arch="amd64">cmdaemon</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-python3</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-boost</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-mariadb-libs</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-atftp-server</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-mysql++</cmrpm>
    <cmrpm install="yes" arch="amd64">pdsh</cmrpm>
    <ExtraPackageGroup name="default" install="yes" media="yes">
      <baserpm install="yes" arch="amd64">libhttp-parser2.9</baserpm>
      <baserpm install="yes" arch="amd64">libhttp-parser-dev</baserpm>
      <baserpm install="yes" arch="amd64">libjwt2</baserpm>
      <baserpm install="yes" arch="amd64">libb64-0d</baserpm>
      <baserpmstore>packagegroups/default</baserpmstore>
      <cmrpmstore>packagegroups/default</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="cuda" install="no" media="yes">
      <baserpm install="yes" arch="all">adwaita-icon-theme</baserpm>
      <baserpm install="yes" arch="amd64">at-spi2-core</baserpm>
      <baserpm install="yes" arch="all">colord-data</baserpm>
      <baserpm install="yes" arch="amd64">colord</baserpm>
      <baserpm install="yes" arch="amd64">dconf-gsettings-backend</baserpm>
      <baserpm install="yes" arch="amd64">dconf-service</baserpm>
      <baserpm install="yes" arch="all">glib-networking-common</baserpm>
      <baserpm install="yes" arch="amd64">glib-networking-services</baserpm>
      <baserpm install="yes" arch="amd64">glib-networking</baserpm>
      <baserpm install="yes" arch="all">gsettings-desktop-schemas</baserpm>
      <baserpm install="yes" arch="all">humanity-icon-theme</baserpm>
      <baserpm install="yes" arch="amd64">libatk-bridge2.0-0t64</baserpm>
      <baserpm install="yes" arch="amd64">libatspi2.0-0t64</baserpm>
      <baserpm install="yes" arch="amd64">libboost-filesystem1.83.0</baserpm>
      <baserpm install="yes" arch="amd64">libboost-system1.83.0</baserpm>
      <baserpm install="yes" arch="amd64">libcairo-gobject2</baserpm>
      <baserpm install="yes" arch="amd64">libcolord2</baserpm>
      <baserpm install="yes" arch="amd64">libcolorhug2</baserpm>
      <baserpm install="yes" arch="amd64">libdconf1</baserpm>
      <baserpm install="yes" arch="amd64">libegl-mesa0</baserpm>
      <baserpm install="yes" arch="amd64">libepoxy0</baserpm>
      <baserpm install="yes" arch="amd64">libexif12</baserpm>
      <baserpm install="yes" arch="amd64">libgbm1</baserpm>
      <baserpm install="yes" arch="amd64">libgphoto2-6t64</baserpm>
      <baserpm install="yes" arch="all">libgphoto2-l10n</baserpm>
      <baserpm install="yes" arch="amd64">libgphoto2-port12t64</baserpm>
      <baserpm install="yes" arch="amd64">libgtk-3-0t64</baserpm>
      <baserpm install="yes" arch="amd64">libgtk-3-bin</baserpm>
      <baserpm install="yes" arch="all">libgtk-3-common</baserpm>
      <baserpm install="yes" arch="amd64">libgudev-1.0-0</baserpm>
      <baserpm install="yes" arch="amd64">libgusb2</baserpm>
      <baserpm install="yes" arch="amd64">libieee1284-3t64</baserpm>
      <baserpm install="yes" arch="amd64">libjson-glib-1.0-0</baserpm>
      <baserpm install="yes" arch="all">libjson-glib-1.0-common</baserpm>
      <baserpm install="yes" arch="amd64">libprotobuf-lite32t64</baserpm>
      <baserpm install="yes" arch="amd64">libproxy1v5</baserpm>
      <baserpm install="yes" arch="amd64">librest-1.0-0</baserpm>
      <baserpm install="yes" arch="amd64">librsvg2-2</baserpm>
      <baserpm install="yes" arch="amd64">librsvg2-common</baserpm>
      <baserpm install="yes" arch="all">libsane-common</baserpm>
      <baserpm install="yes" arch="amd64">libsoup-gnome-2.4-1</baserpm>
      <baserpm install="yes" arch="amd64">libsoup-2.4-1</baserpm>
      <baserpm install="yes" arch="amd64">libwayland-client0</baserpm>
      <baserpm install="yes" arch="amd64">libwayland-cursor0</baserpm>
      <baserpm install="yes" arch="amd64">libwayland-server0</baserpm>
      <baserpm install="yes" arch="amd64">libxcb-xfixes0</baserpm>
      <baserpm install="yes" arch="amd64">libxkbcommon0</baserpm>
      <baserpm install="yes" arch="all">ubuntu-mono</baserpm>
      <baserpm install="yes" arch="amd64">libcapnp-1.0.1</baserpm>
      <baserpm install="yes" arch="amd64">libmircore2t64</baserpm>
      <baserpm install="yes" arch="amd64">acl</baserpm>
      <baserpm install="yes" arch="amd64">avahi-daemon</baserpm>
      <baserpm install="yes" arch="amd64">ipp-usb</baserpm>
      <baserpm install="yes" arch="amd64">libavahi-core7</baserpm>
      <baserpm install="yes" arch="amd64">libdaemon0</baserpm>
      <baserpm install="yes" arch="amd64">libgl1-mesa-dri</baserpm>
      <baserpm install="yes" arch="amd64">libglapi-mesa</baserpm>
      <baserpm install="yes" arch="amd64">libglx-mesa0</baserpm>
      <baserpm install="yes" arch="amd64">libnss-mdns</baserpm>
      <baserpm install="yes" arch="amd64">libpoppler-glib8t64</baserpm>
      <baserpm install="yes" arch="amd64">libpoppler134</baserpm>
      <baserpm install="yes" arch="amd64">libsane1</baserpm>
      <baserpm install="yes" arch="all">poppler-data</baserpm>
      <baserpm install="yes" arch="amd64">sane-airscan</baserpm>
      <baserpm install="yes" arch="amd64">sane-utils</baserpm>
      <baserpm install="yes" arch="all">update-inetd</baserpm>
      <cmrpm install="yes" arch="amd64">cuda12.9-sdk</cmrpm>
      <cmrpm install="yes" arch="amd64">cuda12.9-toolkit</cmrpm>
      <cmrpm install="yes" arch="amd64">cuda12.9-toolkit-libcublas</cmrpm>
      <cmrpm install="yes" arch="amd64">cuda12.9-toolkit-libcufft</cmrpm>
      <cmrpm install="yes" arch="amd64">cuda12.9-toolkit-libcusolver</cmrpm>
      <cmrpm install="yes" arch="amd64">cuda12.9-toolkit-libcusparse</cmrpm>
      <cmrpm install="yes" arch="amd64">cuda-dcgm</cmrpm>
      <cmrpm install="yes" arch="amd64">cuda-dcgm-nvvs</cmrpm>
      <baserpmstore>packagegroups/cuda</baserpmstore>
      <cmrpmstore>packagegroups/cuda</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="cloudimage" install="no" media="no">
      <baserpm install="yes" arch="all">cloud-init</baserpm>
      <baserpm install="yes" arch="all">cloud-guest-utils</baserpm>
      <baserpm install="yes" arch="all">docutils-common</baserpm>
      <baserpm install="yes" arch="all">docutils-doc</baserpm>
      <baserpm install="yes" arch="all">eatmydata</baserpm>
      <baserpm install="yes" arch="amd64">gdisk</baserpm>
      <baserpm install="yes" arch="all">debconf</baserpm>
      <baserpm install="yes" arch="all">init-system-helpers</baserpm>
      <baserpm install="yes" arch="amd64">procps</baserpm>
      <baserpm install="yes" arch="amd64">ifupdown</baserpm>
      <baserpm install="yes" arch="all">javascript-common</baserpm>
      <baserpm install="yes" arch="amd64">libeatmydata1</baserpm>
      <baserpm install="yes" arch="all">libjs-jquery</baserpm>
      <baserpm install="yes" arch="all">libjs-sphinxdoc</baserpm>
      <baserpm install="yes" arch="all">libjs-underscore</baserpm>
      <baserpm install="yes" arch="amd64">libpaper-utils</baserpm>
      <baserpm install="yes" arch="amd64">libpaper1</baserpm>
      <baserpm install="yes" arch="amd64">libwebp7</baserpm>
      <baserpm install="yes" arch="amd64">libwebpmux3</baserpm>
      <baserpm install="yes" arch="all">python3-boto3</baserpm>
      <baserpm install="yes" arch="all">python3-botocore</baserpm>
      <baserpm install="yes" arch="all">python3-dateutil</baserpm>
      <baserpm install="yes" arch="all">python3-docutils</baserpm>
      <baserpm install="yes" arch="all">python3-jmespath</baserpm>
      <baserpm install="yes" arch="amd64">python3-pil</baserpm>
      <baserpm install="yes" arch="all">python3-pygments</baserpm>
      <baserpm install="yes" arch="all">python3-roman</baserpm>
      <baserpm install="yes" arch="all">python3-blinker</baserpm>
      <baserpm install="yes" arch="amd64">python3-cffi-backend</baserpm>
      <baserpm install="yes" arch="all">python3-configobj</baserpm>
      <baserpm install="yes" arch="amd64">python3-cryptography</baserpm>
      <baserpm install="yes" arch="all">python3-idna</baserpm>
      <baserpm install="yes" arch="all">python3-jinja2</baserpm>
      <baserpm install="yes" arch="all">python3-json-pointer</baserpm>
      <baserpm install="yes" arch="all">python3-jsonpatch</baserpm>
      <baserpm install="yes" arch="all">python3-jwt</baserpm>
      <baserpm install="yes" arch="amd64">python3-markupsafe</baserpm>
      <baserpm install="yes" arch="all">python3-oauthlib</baserpm>
      <baserpm install="yes" arch="all">python3-prettytable</baserpm>
      <baserpm install="yes" arch="all">python3-pyasn1</baserpm>
      <baserpm install="yes" arch="all">python3-serial</baserpm>
      <baserpm install="yes" arch="amd64">python3-yaml</baserpm>
      <baserpm install="yes" arch="all">python3-six</baserpm>
      <baserpm install="yes" arch="all">python3-requests</baserpm>
      <baserpm install="yes" arch="all">python3-s3transfer</baserpm>
      <baserpmstore>packagegroups/cloudimage</baserpmstore>
      <cmrpmstore>packagegroups/cloudimage</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="ansible-installer" install="no" media="yes">
      <baserpm install="yes" arch="amd64">build-essential</baserpm>
      <baserpm install="yes" arch="amd64">galera-4</baserpm>
      <baserpm install="yes" arch="amd64">libc6</baserpm>
      <baserpm install="yes" arch="all">libcgi-fast-perl</baserpm>
      <baserpm install="yes" arch="all">libcgi-pm-perl</baserpm>
      <baserpm install="yes" arch="all">libconfig-inifiles-perl</baserpm>
      <baserpm install="yes" arch="amd64">libdaxctl1</baserpm>
      <baserpm install="yes" arch="amd64">libexpat1-dev</baserpm>
      <baserpm install="yes" arch="amd64">libfcgi-bin</baserpm>
      <baserpm install="yes" arch="amd64">libfcgi-perl</baserpm>
      <baserpm install="yes" arch="all">libhtml-template-perl</baserpm>
      <baserpm install="yes" arch="amd64">libldap-dev</baserpm>
      <baserpm install="yes" arch="all">libldap2-dev</baserpm>
      <baserpm install="yes" arch="amd64">libmariadb3</baserpm>
      <baserpm install="yes" arch="amd64">libndctl6</baserpm>
      <baserpm install="yes" arch="amd64">libpmem1</baserpm>
      <baserpm install="yes" arch="amd64">libpython3-dev</baserpm>
      <baserpm install="yes" arch="amd64">libpython3.12-dev</baserpm>
      <baserpm install="yes" arch="amd64">libsasl2-dev</baserpm>
      <baserpm install="yes" arch="amd64">libsnappy1v5</baserpm>
      <baserpm install="yes" arch="amd64">libssl-dev</baserpm>
      <baserpm install="yes" arch="amd64">liburing2</baserpm>
      <baserpm install="yes" arch="amd64">libuser</baserpm>
      <baserpm install="yes" arch="amd64">libuser1</baserpm>
      <baserpm install="yes" arch="amd64">libxml2-utils</baserpm>
      <baserpm install="yes" arch="amd64">mariadb-client</baserpm>
      <baserpm install="yes" arch="amd64">mariadb-client-core</baserpm>
      <baserpm install="yes" arch="all">mariadb-common</baserpm>
      <baserpm install="yes" arch="amd64">mariadb-server</baserpm>
      <baserpm install="yes" arch="amd64">mariadb-server-core</baserpm>
      <baserpm install="yes" arch="amd64">python3-cryptography</baserpm>
      <baserpm install="yes" arch="amd64">python3-dev</baserpm>
      <baserpm install="yes" arch="all">python3-pip</baserpm>
      <baserpm install="yes" arch="all">python3-pymysql</baserpm>
      <baserpm install="yes" arch="all">python3-wheel</baserpm>
      <baserpm install="yes" arch="amd64">python3.12-dev</baserpm>
      <baserpm install="yes" arch="amd64">socat</baserpm>
      <baserpm install="yes" arch="amd64">zlib1g</baserpm>
      <baserpm install="yes" arch="amd64">libdbus-1-3</baserpm>
      <baserpm install="yes" arch="all">python3-distutils-extra</baserpm>
      <baserpm install="yes" arch="all">python3-lib2to3</baserpm>
      <baserpm install="yes" arch="amd64">gcc-12-base</baserpm>
      <baserpm install="yes" arch="amd64">libgcc-s1</baserpm>
      <baserpm install="yes" arch="amd64">libstdc++6</baserpm>
      <baserpm install="yes" arch="amd64">libexpat1-dev</baserpm>
      <baserpm install="yes" arch="amd64">libexpat1</baserpm>
      <baserpm install="yes" arch="amd64">dbus</baserpm>
      <baserpm install="yes" arch="amd64">dbus-x11</baserpm>
      <baserpm install="yes" arch="amd64">libdbus-1-3</baserpm>
      <baserpm install="yes" arch="amd64">libx11-6</baserpm>
      <baserpm install="yes" arch="amd64">libx11-xcb1</baserpm>
      <baserpm install="yes" arch="amd64">libbz2-1.0</baserpm>
      <baserpm install="yes" arch="all">dbus-session-bus-common</baserpm>
      <baserpm install="yes" arch="all">dbus-system-bus-common</baserpm>
      <baserpm install="yes" arch="all">fonts-dejavu-mono</baserpm>
      <baserpm install="yes" arch="all">libdrm-common</baserpm>
      <baserpm install="yes" arch="all">linux-tools-common</baserpm>
      <baserpm install="yes" arch="all">locales</baserpm>
      <baserpm install="yes" arch="all">systemd-dev</baserpm>
      <baserpm install="yes" arch="all">libx11-data</baserpm>
      <baserpm install="yes" arch="amd64">dbus-bin</baserpm>
      <baserpm install="yes" arch="amd64">dbus-daemon</baserpm>
      <baserpm install="yes" arch="amd64">dbus-user-session</baserpm>
      <baserpm install="yes" arch="amd64">dpkg</baserpm>
      <baserpm install="yes" arch="amd64">libaom3</baserpm>
      <baserpm install="yes" arch="amd64">libattr1</baserpm>
      <baserpm install="yes" arch="amd64">libc-bin</baserpm>
      <baserpm install="yes" arch="amd64">libde265-0</baserpm>
      <baserpm install="yes" arch="amd64">libdrm2</baserpm>
      <baserpm install="yes" arch="amd64">libheif-plugin-aomdec</baserpm>
      <baserpm install="yes" arch="amd64">libheif-plugin-aomenc</baserpm>
      <baserpm install="yes" arch="amd64">libheif-plugin-libde265</baserpm>
      <baserpm install="yes" arch="amd64">libheif1</baserpm>
      <baserpm install="yes" arch="amd64">liblerc4</baserpm>
      <baserpm install="yes" arch="amd64">libpolkit-agent-1-0</baserpm>
      <baserpm install="yes" arch="amd64">libpolkit-gobject-1-0</baserpm>
      <baserpm install="yes" arch="amd64">libsharpyuv0</baserpm>
      <baserpm install="yes" arch="amd64">libsystemd-shared</baserpm>
      <baserpm install="yes" arch="amd64">libudev1</baserpm>
      <baserpm install="yes" arch="amd64">libxau6</baserpm>
      <baserpm install="yes" arch="amd64">libxcb1</baserpm>
      <baserpm install="yes" arch="amd64">libxdmcp6</baserpm>
      <baserpm install="yes" arch="amd64">libxext6</baserpm>
      <baserpm install="yes" arch="amd64">libxmuu1</baserpm>
      <baserpm install="yes" arch="all">linux-headers-6.8.0-51</baserpm>
      <baserpm install="yes" arch="amd64">linux-headers-generic</baserpm>
      <baserpm install="yes" arch="amd64">linux-image-generic</baserpm>
      <baserpm install="yes" arch="amd64">polkitd</baserpm>
      <baserpm install="yes" arch="amd64">systemd-resolved</baserpm>
      <baserpm install="yes" arch="amd64">udev</baserpm>
      <baserpm install="yes" arch="amd64">xauth</baserpm>
      <baserpmstore>packagegroups/ansible-installer</baserpmstore>
      <cmrpmstore>packagegroups/ansible-installer</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="doca_ofed_2.9.3" install="no" media="yes">
      <package-no>ibsim-utils</package-no>
      <package-no>ibutils</package-no>
      <package-no>libumad2sim0</package-no>
      <baserpm install="yes" arch="amd64">doca-ofed</baserpm>
      <baserpm install="yes" arch="amd64">dpcp</baserpm>
      <baserpm install="yes" arch="amd64">hcoll</baserpm>
      <baserpm install="yes" arch="amd64">ibacm</baserpm>
      <baserpm install="yes" arch="amd64">ibarr</baserpm>
      <baserpm install="yes" arch="amd64">ibdump</baserpm>
      <baserpm install="yes" arch="amd64">ibsim</baserpm>
      <baserpm install="yes" arch="all">ibsim-doc</baserpm>
      <baserpm install="yes" arch="amd64">ibutils2</baserpm>
      <baserpm install="yes" arch="amd64">ibverbs-providers</baserpm>
      <baserpm install="yes" arch="amd64">ibverbs-utils</baserpm>
      <baserpm install="yes" arch="amd64">infiniband-diags</baserpm>
      <baserpm install="yes" arch="all">iser-dkms</baserpm>
      <baserpm install="yes" arch="all">isert-dkms</baserpm>
      <baserpm install="yes" arch="all">kernel-mft-dkms</baserpm>
      <baserpm install="yes" arch="amd64">knem</baserpm>
      <baserpm install="yes" arch="all">knem-dkms</baserpm>
      <baserpm install="yes" arch="amd64">libibmad-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibmad5</baserpm>
      <baserpm install="yes" arch="amd64">libibnetdisc5</baserpm>
      <baserpm install="yes" arch="amd64">libibumad-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibumad3</baserpm>
      <baserpm install="yes" arch="amd64">libibverbs-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibverbs1</baserpm>
      <baserpm install="yes" arch="amd64">libopensm</baserpm>
      <baserpm install="yes" arch="amd64">libopensm-devel</baserpm>
      <baserpm install="yes" arch="amd64">librdmacm-dev</baserpm>
      <baserpm install="yes" arch="amd64">librdmacm1</baserpm>
      <baserpm install="yes" arch="amd64">libxpmem-dev</baserpm>
      <baserpm install="yes" arch="amd64">libxpmem0</baserpm>
      <baserpm install="yes" arch="amd64">mft</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-ethtool</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-iproute2</baserpm>
      <baserpm install="yes" arch="all">mlnx-ofed-kernel-dkms</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-ofed-kernel-utils</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-tools</baserpm>
      <baserpm install="yes" arch="amd64">mpitests</baserpm>
      <baserpm install="yes" arch="amd64">ofed-scripts</baserpm>
      <baserpm install="yes" arch="all">openmpi</baserpm>
      <baserpm install="yes" arch="amd64">opensm</baserpm>
      <baserpm install="yes" arch="amd64">opensm-doc</baserpm>
      <baserpm install="yes" arch="amd64">perftest</baserpm>
      <baserpm install="yes" arch="amd64">rdma-core</baserpm>
      <baserpm install="yes" arch="amd64">rdmacm-utils</baserpm>
      <baserpm install="yes" arch="amd64">rshim</baserpm>
      <baserpm install="yes" arch="amd64">sharp</baserpm>
      <baserpm install="yes" arch="all">srp-dkms</baserpm>
      <baserpm install="yes" arch="amd64">srptools</baserpm>
      <baserpm install="yes" arch="amd64">ucx</baserpm>
      <baserpm install="yes" arch="all">xpmem</baserpm>
      <baserpm install="yes" arch="all">xpmem-dkms</baserpm>
      <baserpmstore>packagegroups/doca_ofed_2.9.3</baserpmstore>
      <cmrpmstore>packagegroups/doca_ofed_2.9.3</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="doca_ofed_3.1.0" install="no" media="yes">
      <package-no>ibsim-utils</package-no>
      <package-no>ibutils</package-no>
      <package-no>libumad2sim0</package-no>
      <package-no>libopensm9</package-no>
      <package-no>libibdm1</package-no>
      <package-no>libosmvendor5</package-no>
      <baserpm install="yes" arch="amd64">doca-ofed</baserpm>
      <baserpm install="yes" arch="amd64">dpcp</baserpm>
      <baserpm install="yes" arch="amd64">hcoll</baserpm>
      <baserpm install="yes" arch="amd64">ibacm</baserpm>
      <baserpm install="yes" arch="amd64">ibarr</baserpm>
      <baserpm install="yes" arch="amd64">ibdump</baserpm>
      <baserpm install="yes" arch="amd64">ibsim</baserpm>
      <baserpm install="yes" arch="all">ibsim-doc</baserpm>
      <baserpm install="yes" arch="amd64">ibutils2</baserpm>
      <baserpm install="yes" arch="amd64">ibverbs-providers</baserpm>
      <baserpm install="yes" arch="amd64">ibverbs-utils</baserpm>
      <baserpm install="yes" arch="amd64">infiniband-diags</baserpm>
      <baserpm install="yes" arch="all">iser-dkms</baserpm>
      <baserpm install="yes" arch="all">isert-dkms</baserpm>
      <baserpm install="yes" arch="all">kernel-mft-dkms</baserpm>
      <baserpm install="yes" arch="amd64">knem</baserpm>
      <baserpm install="yes" arch="all">knem-dkms</baserpm>
      <baserpm install="yes" arch="amd64">libibmad-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibmad5</baserpm>
      <baserpm install="yes" arch="amd64">libibnetdisc5</baserpm>
      <baserpm install="yes" arch="amd64">libibumad-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibumad3</baserpm>
      <baserpm install="yes" arch="amd64">libibverbs-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibverbs1</baserpm>
      <baserpm install="yes" arch="amd64">libopensm</baserpm>
      <baserpm install="yes" arch="amd64">libopensm-devel</baserpm>
      <baserpm install="yes" arch="amd64">librdmacm-dev</baserpm>
      <baserpm install="yes" arch="amd64">librdmacm1</baserpm>
      <baserpm install="yes" arch="amd64">libxpmem-dev</baserpm>
      <baserpm install="yes" arch="amd64">libxpmem0</baserpm>
      <baserpm install="yes" arch="amd64">mft</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-ethtool</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-iproute2</baserpm>
      <baserpm install="yes" arch="all">mlnx-ofed-kernel-dkms</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-ofed-kernel-utils</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-tools</baserpm>
      <baserpm install="yes" arch="amd64">mpitests</baserpm>
      <baserpm install="yes" arch="amd64">ofed-scripts</baserpm>
      <baserpm install="yes" arch="all">openmpi</baserpm>
      <baserpm install="yes" arch="amd64">opensm</baserpm>
      <baserpm install="yes" arch="amd64">opensm-doc</baserpm>
      <baserpm install="yes" arch="amd64">perftest</baserpm>
      <baserpm install="yes" arch="amd64">rdma-core</baserpm>
      <baserpm install="yes" arch="amd64">rdmacm-utils</baserpm>
      <baserpm install="yes" arch="amd64">rshim</baserpm>
      <baserpm install="yes" arch="amd64">sharp</baserpm>
      <baserpm install="yes" arch="all">srp-dkms</baserpm>
      <baserpm install="yes" arch="amd64">srptools</baserpm>
      <baserpm install="yes" arch="amd64">ucx</baserpm>
      <baserpm install="yes" arch="all">xpmem</baserpm>
      <baserpm install="yes" arch="all">xpmem-dkms</baserpm>
      <baserpmstore>packagegroups/doca_ofed_3.1.0</baserpmstore>
      <cmrpmstore>packagegroups/doca_ofed_3.1.0</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="doca_ofed_3.1.0-091513" install="no" media="yes">
      <package-no>ibsim-utils</package-no>
      <package-no>ibutils</package-no>
      <package-no>libumad2sim0</package-no>
      <package-no>libopensm9</package-no>
      <package-no>libibdm1</package-no>
      <package-no>libosmvendor5</package-no>
      <baserpmstore>packagegroups/doca_ofed_3.1.0-091513</baserpmstore>
      <cmrpmstore>packagegroups/doca_ofed_3.1.0-091513</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="doca_ofed_3.1.0-091548" install="no" media="yes">
      <package-no>ibsim-utils</package-no>
      <package-no>ibutils</package-no>
      <package-no>libumad2sim0</package-no>
      <package-no>libopensm9</package-no>
      <package-no>libibdm1</package-no>
      <package-no>libosmvendor5</package-no>
      <baserpm install="yes" arch="amd64">doca-ofed</baserpm>
      <baserpm install="yes" arch="amd64">dpcp</baserpm>
      <baserpm install="yes" arch="amd64">hcoll</baserpm>
      <baserpm install="yes" arch="amd64">ibacm</baserpm>
      <baserpm install="yes" arch="amd64">ibarr</baserpm>
      <baserpm install="yes" arch="amd64">ibdump</baserpm>
      <baserpm install="yes" arch="amd64">ibsim</baserpm>
      <baserpm install="yes" arch="all">ibsim-doc</baserpm>
      <baserpm install="yes" arch="amd64">ibutils2</baserpm>
      <baserpm install="yes" arch="amd64">ibverbs-providers</baserpm>
      <baserpm install="yes" arch="amd64">ibverbs-utils</baserpm>
      <baserpm install="yes" arch="amd64">infiniband-diags</baserpm>
      <baserpm install="yes" arch="all">iser-dkms</baserpm>
      <baserpm install="yes" arch="all">isert-dkms</baserpm>
      <baserpm install="yes" arch="all">kernel-mft-dkms</baserpm>
      <baserpm install="yes" arch="amd64">knem</baserpm>
      <baserpm install="yes" arch="all">knem-dkms</baserpm>
      <baserpm install="yes" arch="amd64">libibmad-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibmad5</baserpm>
      <baserpm install="yes" arch="amd64">libibnetdisc5</baserpm>
      <baserpm install="yes" arch="amd64">libibumad-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibumad3</baserpm>
      <baserpm install="yes" arch="amd64">libibverbs-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibverbs1</baserpm>
      <baserpm install="yes" arch="amd64">libopensm</baserpm>
      <baserpm install="yes" arch="amd64">libopensm-devel</baserpm>
      <baserpm install="yes" arch="amd64">librdmacm-dev</baserpm>
      <baserpm install="yes" arch="amd64">librdmacm1</baserpm>
      <baserpm install="yes" arch="amd64">libxpmem-dev</baserpm>
      <baserpm install="yes" arch="amd64">libxpmem0</baserpm>
      <baserpm install="yes" arch="amd64">mft</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-ethtool</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-iproute2</baserpm>
      <baserpm install="yes" arch="all">mlnx-ofed-kernel-dkms</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-ofed-kernel-utils</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-tools</baserpm>
      <baserpm install="yes" arch="amd64">mpitests</baserpm>
      <baserpm install="yes" arch="amd64">ofed-scripts</baserpm>
      <baserpm install="yes" arch="all">openmpi</baserpm>
      <baserpm install="yes" arch="amd64">opensm</baserpm>
      <baserpm install="yes" arch="amd64">opensm-doc</baserpm>
      <baserpm install="yes" arch="amd64">perftest</baserpm>
      <baserpm install="yes" arch="amd64">rdma-core</baserpm>
      <baserpm install="yes" arch="amd64">rdmacm-utils</baserpm>
      <baserpm install="yes" arch="amd64">rshim</baserpm>
      <baserpm install="yes" arch="amd64">sharp</baserpm>
      <baserpm install="yes" arch="all">srp-dkms</baserpm>
      <baserpm install="yes" arch="amd64">srptools</baserpm>
      <baserpm install="yes" arch="amd64">ucx</baserpm>
      <baserpm install="yes" arch="all">xpmem</baserpm>
      <baserpm install="yes" arch="all">xpmem-dkms</baserpm>
      <baserpmstore>packagegroups/doca_ofed_3.1.0-091548</baserpmstore>
      <cmrpmstore>packagegroups/doca_ofed_3.1.0-091548</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="hpc" install="yes" media="yes">
      <cmrpm install="yes" arch="amd64">hdf518</cmrpm>
      <cmrpm install="yes" arch="amd64">hpl</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05-slurmd</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05-slurmctld</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05-slurmdbd</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05-contribs</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05-perlapi</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05-devel</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05-prs</cmrpm>
      <cmrpm install="yes" arch="all">pyxis-sources</cmrpm>
      <cmrpm install="yes" arch="amd64">enroot</cmrpm>
      <cmrpm install="yes" arch="amd64">enroot+caps</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-openblas</cmrpm>
      <cmrpm install="yes" arch="amd64">mvapich2-gcc</cmrpm>
      <cmrpm install="yes" arch="amd64">openmpi4-gcc</cmrpm>
      <cmrpm install="yes" arch="all">cm-workload</cmrpm>
      <cmrpm install="yes" arch="amd64">openpbs23.06</cmrpm>
      <cmrpm install="yes" arch="amd64">openpbs23.06-client</cmrpm>
      <cmrpm install="yes" arch="all">cm-lsf</cmrpm>
      <cmrpm install="yes" arch="all">cm-lsf-client</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-ucx</cmrpm>
      <cmrpm install="yes" arch="all">cm-uge</cmrpm>
      <cmrpm install="yes" arch="all">cm-uge-client</cmrpm>
      <cmrpm install="yes" arch="amd64">munge</cmrpm>
      <cmrpm install="yes" arch="amd64">libmunge2</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-pmix3</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-pmix4</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-hwloc</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-hwloc2</cmrpm>
      <baserpmstore>packagegroups/hpc</baserpmstore>
      <cmrpmstore>packagegroups/hpc</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="cm-lite-daemon-ubuntu18.04" install="no" media="yes">
      <cmrpm install="yes" arch="all">cm-lite-daemon</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-openssl</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-python312</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-python3</cmrpm>
      <cmrpm install="yes" arch="all">cm-config-cm</cmrpm>
      <baserpmstore>packagegroups/cm-lite-daemon-ubuntu18.04</baserpmstore>
      <cmrpmstore>packagegroups/cm-lite-daemon-ubuntu18.04</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="cm-lite-daemon-ubuntu20.04" install="no" media="yes">
      <cmrpm install="yes" arch="all">cm-lite-daemon</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-openssl</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-python312</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-python3</cmrpm>
      <cmrpm install="yes" arch="all">cm-config-cm</cmrpm>
      <baserpmstore>packagegroups/cm-lite-daemon-ubuntu20.04</baserpmstore>
      <cmrpmstore>packagegroups/cm-lite-daemon-ubuntu20.04</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="cm-lite-daemon-ubuntu22.04" install="no" media="yes">
      <cmrpm install="yes" arch="all">cm-lite-daemon</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-openssl</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-python312</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-python3</cmrpm>
      <cmrpm install="yes" arch="all">cm-config-cm</cmrpm>
      <baserpmstore>packagegroups/cm-lite-daemon-ubuntu22.04</baserpmstore>
      <cmrpmstore>packagegroups/cm-lite-daemon-ubuntu22.04</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="cm-lite-daemon-ubuntu24.04" install="no" media="yes">
      <cmrpm install="yes" arch="all">cm-lite-daemon</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-openssl</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-python312</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-python3</cmrpm>
      <cmrpm install="yes" arch="all">cm-config-cm</cmrpm>
      <baserpmstore>packagegroups/cm-lite-daemon-ubuntu24.04</baserpmstore>
      <cmrpmstore>packagegroups/cm-lite-daemon-ubuntu24.04</cmrpmstore>
    </ExtraPackageGroup>
  </MasterConfig>
  <License>
    <country>US</country>
    <state>California</state>
    <locality>San Jose</locality>
    <organization>NVIDIA</organization>
    <unit>Development</unit>
    <mac>??:??:??:??:??:??</mac>
    <max_nodes>3</max_nodes>
    <version>11.0</version>
    <edition>Advanced</edition>
    <enddate>08/01/38</enddate>
  </License>
  <SlaveCategory>
    <name>default</name>
    <managementnetwork>internalnet</managementnetwork>
    <default>x86_64</default>
    <image>default-image</image>
    <network>eth.cluster</network>
    <excludelists>
      <full><![CDATA[# For details on the exclude patterns defined here please refer to
# the FILTER RULES section of the rsync man page.
#
# Files that match these patterns will not be installed onto the node.
- lost+found/
- /proc/*
- /sys/*
- /boot/efi


]]></full>
      <grab><![CDATA[- /.autofsck
- /boot/efi
- /boot/grub/device.map
- /boot/grub/grub.conf
- /boot/grub/menu.lst
- /boot/grub*/device.map
- /boot/grub*/grub.cfg
- /boot/grub*/grubenv
- /cgroup/*
- /cm/images/*
- /cm/local/apps/cmd/etc/cert.*
- /cm/local/apps/openldap/etc/certs/ldap.key
- /cm/local/apps/openldap/etc/certs/ldap.pem
- /cm/node-installer/*
- /cm/node-installer-ebs/*
- /cm/shared/*
- /data/*
- /dev/*
- /etc/aliases.db
- /etc/blkid/*
- /etc/exports
- /etc/fstab
- /etc/HOSTNAME
- /etc/hostname
- /etc/hosts
- /etc/lvm/cache/*
- /etc/lvm/archive/*
- /etc/lvm/backup/*
- /etc/mtab
- /etc/ntp.conf
- /etc/ntp/*
- /etc/ntpsec/ntp.conf
- /etc/chrony.conf
- /etc/openvpn/*
- /etc/postfix/main.cf
- /etc/resolv.conf
- /etc/sysconfig/network
- /etc/sysconfig/network-scripts/ifcfg-eth*
- /etc/sysconfig/network-scripts/ifcfg-em*
- /etc/sysconfig/network-scripts/ifcfg-eno*
- /etc/sysconfig/network-scripts/ifcfg-enp*
- /etc/sysconfig/network-scripts/ifcfg-ens*
- /etc/sysconfig/network-scripts/ifcfg-enx*
- /etc/sysconfig/network-scripts/ifcfg-ib*
- /etc/sysconfig/network-scripts/ifcfg-br*
- /etc/sysconfig/network-scripts/ifcfg-bond*
- /etc/sysconfig/network-scripts/ifcfg-p*
- /etc/network/interfaces.d/*
- /etc/udev/rules.d/*-persistent-*
- /fhgfs/*
- /local/*
- lost+found/
- /media/*
- /proc/*
- /run/*
- /scratch/*
- /sys/*
- /tftpboot/*
- /tmp/*
- /var/cache/yum/*
- /var/cache/dnf/*
- /var/lib/dhclient/*
- /var/lib/dhcpcd/*
- /var/lib/ldap/*
- /var/lib/logrotate.status
- /var/lib/mlocate/*
- /var/lib/nfs/*
- /var/lib/ntp/drift
- /var/lib/ntp/proc/*
- /var/lib/ntpsec/*
- /var/lib/chrony/*
- /var/lib/rpm/__db.*
- /var/lib/sss/*
- /var/lib/systemd/random-seed
- /var/lock/subsys/*
- /var/log/*
- /var/run/*.pid
- /var/run/*/*.pid
- /var/spool/anacron/*
- /var/spool/cmd/*
- /var/spool/mail/*
- /var/spool/postfix/*
- /var/tmp/*


]]></grab>
      <grabnew><![CDATA[- /.autofsck
- /boot/efi
- /cgroup/*
- /cm/images/*
- /cm/local/apps/cmd/etc/cert.*
- /cm/local/apps/openldap/etc/certs/ldap.key
- /cm/local/apps/openldap/etc/certs/ldap.pem
- /cm/node-installer/*
- /cm/node-installer-ebs/*
- /cm/shared/*
- /dev/.udev/*
- /dev/bus/*
- /dev/cpu/*
- /dev/disk/by-id/*
- /dev/disk/by-path/*
- /dev/disk/by-uuid/*
- /dev/infiniband/*
- /dev/shm/*
- /dev/usbdev*
- /etc/HOSTNAME
- /etc/hostname
- /etc/lvm/cache/*
- /etc/lvm/archive/*
- /etc/lvm/backup/*
- /etc/openvpn/*
- /etc/resolv.conf
- /etc/sysconfig/network-scripts/ifcfg-eth*
- /etc/sysconfig/network-scripts/ifcfg-em*
- /etc/sysconfig/network-scripts/ifcfg-eno*
- /etc/sysconfig/network-scripts/ifcfg-enp*
- /etc/sysconfig/network-scripts/ifcfg-ens*
- /etc/sysconfig/network-scripts/ifcfg-enx*
- /etc/sysconfig/network-scripts/ifcfg-ib*
- /etc/sysconfig/network-scripts/ifcfg-br*
- /etc/sysconfig/network-scripts/ifcfg-bond*
- /etc/sysconfig/network-scripts/ifcfg-p*
- /etc/network/interfaces.d/*
- /etc/udev/rules.d/*-persistent-*
- lost+found/
- /media/*
- /proc/*
- /run/*
- /sys/*
- /tftpboot/*
- /tmp/*
- /var/cache/yum/*
- /var/cache/dnf/*
- /var/lib/dhclient/*
- /var/lib/dhcpcd/*
- /var/lib/logrotate.status
- /var/lib/mlocate/*
- /var/lib/ntp/proc/*
- /var/lib/systemd/random-seed
- /var/spool/anacron/*
- /var/spool/cmd/*
- /var/log/node-installer
- /var/tmp/*
- /var/lib/sss/*


]]></grabnew>
      <sync><![CDATA[# For details on the exclude patterns defined here please refer to
# the FILTER RULES section of the rsync man page.
#
# Files that exist on a node and match one of these patterns will not be
# modified or deleted. Any files that match one of these patterns and that
# exist in the image but are absent on the node, will be copied to the node.
- /.autofsck
- /boot/grub*/grub.cfg
- /cm/local/apps/openldap/etc/certs/ldap.key
- /cm/local/apps/openldap/etc/certs/ldap.pem
- /data/*
- /home/*
- /local/*
- /scratch/*
- /tmp/*
- /var/log/*
- /var/tmp/*
- /var/spool/mail/*
- /var/spool/postfix/*

# Files that exist on a node and match one of these patterns will not be
# modified or deleted. Any files that match one of these patterns and that
# exist in the image will never be copied to the node.
# (The prefix "no-new-files: " will be removed before passing to rsync.)
no-new-files: - /boot/efi
no-new-files: - /cm/images
no-new-files: - /cm/shared/*
no-new-files: - lost+found/
no-new-files: - /proc/*
no-new-files: - /sys/*
no-new-files: - /tftpboot/*
no-new-files: - /.autorelabel
no-new-files: - /var/lib/logrotate.status
no-new-files: - /var/lib/sss/*
no-new-files: - /var/lib/systemd/random-seed
no-new-files: - /var/spool/anacron/*


]]></sync>
      <update><![CDATA[# For details on the exclude patterns defined here please refer to
# the FILTER RULES section of the rsync man page.
#
# Files that exist on a node and match one of these patterns will not be
# modified or deleted. Any files that match one of these patterns and that
# exist in the image but are absent on the node, will be copied to the node.
- /.autofsck
- /.autorelabel
- /boot/boot
- /boot/grub/device.map
- /boot/grub/grub.conf
- /boot/grub/menu.lst
- /boot/grub*/device.map
- /boot/grub*/fonts
- /boot/grub*/grub.cfg
- /boot/grub*/grubenv
- /boot/grub*/i386-pc
- /boot/grub*/locale
- /boot/grub2
- /boot/initrd-*.orig
- /cm/local/apps/cmd/etc/*
- /cm/local/apps/openldap/etc/certs/ldap.key
- /cm/local/apps/openldap/etc/certs/ldap.pem
- /data/*
- /etc/aliases.db
- /etc/blkid/*
- /etc/cm/burnrc
- /etc/dhcpd.*
- /etc/exports
- /etc/fstab
- /etc/hosts
- /etc/HOSTNAME
- /etc/hostname
- /etc/lvm/cache/.cache
- /etc/lvm/archive/*
- /etc/lvm/backup/*
- /etc/mtab
- /etc/ntp.conf
- /etc/ntp/step-tickers
- /etc/ntpsec/ntp.conf
- /etc/chrony.conf
- /etc/openvpn
- /etc/pam.d/sshd
- /etc/postfix/main.cf
- /etc/rc.d/rc*.d/*dhcpd
- /etc/rc.d/rc*.d/*maui
- /etc/rc.d/rc*.d/*moab
- /etc/rc.d/rc*.d/*munge
- /etc/rc.d/rc*.d/*nfs
- /etc/rc.d/rc*.d/*opensmd
- /etc/rc.d/rc*.d/*opensm
- /etc/rc.d/rc*.d/*pbs_mom
- /etc/rc.d/rc*.d/*pbs
- /etc/rc.d/rc*.d/*portmap
- /etc/rc.d/rc*.d/*rpcbind
- /etc/rc.d/rc*.d/*sgemaster.sge1
- /etc/rc.d/rc*.d/*sgeexecd
- /etc/rc.d/rc*.d/*slurm
- /etc/rc.d/rc*.d/*slurmdbd
- /etc/reader.conf
- /etc/resolv.conf
- /etc/security/pam_bright.d/cm-check-alloc.conf
- /etc/sensors3.conf
- /etc/sysconfig/network
- /etc/sysconfig/network-scripts/ifcfg-*
- /etc/network/interfaces.d/*
- /etc/sysconfig/openib
- /etc/systemd/system/*.wants/dhcpd.service
- /etc/systemd/system/*.wants/maui.service
- /etc/systemd/system/*.wants/moab.service
- /etc/systemd/system/*.wants/munge.service
- /etc/systemd/system/*.wants/nfs.service
- /etc/systemd/system/*.wants/opensmd.service
- /etc/systemd/system/*.wants/opensm.service
- /etc/systemd/system/*.wants/pbs_mom.service
- /etc/systemd/system/*.wants/pbs.service
- /etc/systemd/system/*.wants/portmap.service
- /etc/systemd/system/*.wants/rpcbind.service
- /etc/systemd/system/*.wants/sgemaster.sge1.service
- /etc/systemd/system/*.wants/sgeexecd.service
- /etc/systemd/system/*.wants/slurmctld.service
- /etc/systemd/system/*.wants/slurmd.service
- /etc/systemd/system/*.wants/slurmdbd.service
- /fhgfs/*
- /home/*
- /local/*
- /mnt/*
- /root/.bash_history
- /root/.modulesbeginenv
- /root/.ssh/known_hosts
- /scratch/*
- /tmp/*
- /var/cache/man/*
- /var/empty/*
- /var/lib/dhclient/*
- /var/lib/dhcp/*
- /var/lib/dhcpcd/*
- /var/lib/gssproxy/default.sock
- /var/lib/logrotate.status
- /var/lib/misc/postfix.aliasesdb-stamp
- /var/lib/mlocate/*
- /var/lib/nfs/*
- /var/lib/ntp/drift
- /var/lib/ntp/proc
- /var/lib/ntpsec/*
- /var/lib/chrony/*
- /var/lib/plymouth/boot-duration
- /var/lib/postfix/master.lock
- /var/lib/random-seed
- /var/log/*
- /var/net-snmp*
- /var/spool/*
- /var/tmp/*

# OFED
- /usr/sbin/ibpd
- /etc/infiniband
- /usr/bin/ibdev2netdev
- /etc/modprobe.d/mlx4_en.conf
- /etc/modprobe.d/ib*.conf
- /etc/rc.d/*/*openibd
- /etc/udev/rules.d/*-ibpd.rules
- /etc/udev/rules.d/*-ib.rules
- /etc/udev/rules.d/*-persistent-net.rules
- /etc/udev/rules.d/*-persistent-cd.rules
- /sbin/connectx_port_config
- /sbin/sysctl_perf_tuning
- /var/cache/sysctl_perf_tuning

# Files that exist on a node and match one of these patterns will not be
# modified or deleted. Any files that match one of these patterns and that
# exist in the image will never be copied to the node.
# (The prefix "no-new-files: " will be removed before passing to rsync.)
no-new-files: - /boot/efi
no-new-files: - /cgroup/*
no-new-files: - /cm/images
no-new-files: - /cm/node-installer-ebs
no-new-files: - /cm/shared/*
no-new-files: - /dev/*
no-new-files: - lost+found/
no-new-files: - /media/*
no-new-files: - /proc/*
no-new-files: - /run/*
no-new-files: - /sys/*
no-new-files: - /tftpboot/*
no-new-files: - /var/lock/*
no-new-files: - /var/lib/ldap/*
no-new-files: - /var/lib/rpm/__db.*
no-new-files: - /var/lib/sss/*
no-new-files: - /var/lib/systemd/random-seed
no-new-files: - /var/run/*
no-new-files: - /var/spool/anacron/*
no-new-files: - /.autorelabel


]]></update>
    </excludelists>
    <fsmount>
      <device>none</device>
      <mountpoint>/dev/pts</mountpoint>
      <filesystem>devpts</filesystem>
      <mountoptions>gid=5,mode=620</mountoptions>
      <dump>0</dump>
      <fsck>0</fsck>
    </fsmount>
    <fsmount>
      <device>none</device>
      <mountpoint>/proc</mountpoint>
      <filesystem>proc</filesystem>
      <mountoptions>defaults,nosuid</mountoptions>
      <dump>0</dump>
      <fsck>0</fsck>
    </fsmount>
    <fsmount>
      <device>none</device>
      <mountpoint>/sys</mountpoint>
      <filesystem>sysfs</filesystem>
      <mountoptions>defaults</mountoptions>
      <dump>0</dump>
      <fsck>0</fsck>
    </fsmount>
    <fsmount>
      <device>none</device>
      <mountpoint>/dev/shm</mountpoint>
      <filesystem>tmpfs</filesystem>
      <mountoptions>defaults</mountoptions>
      <dump>0</dump>
      <fsck>0</fsck>
    </fsmount>
    <fsmount>
      <device>$localnfsserver:/cm/shared</device>
      <mountpoint>/cm/shared</mountpoint>
      <filesystem>nfs</filesystem>
      <mountoptions>rsize=32768,wsize=32768,hard,async</mountoptions>
      <dump>0</dump>
      <fsck>0</fsck>
    </fsmount>
    <fsmount>
      <device>$localnfsserver:/home</device>
      <mountpoint>/home</mountpoint>
      <filesystem>nfs</filesystem>
      <mountoptions>rsize=32768,wsize=32768,hard,async</mountoptions>
      <dump>0</dump>
      <fsck>0</fsck>
    </fsmount>
    <bootLoader>syslinux</bootLoader>
  </SlaveCategory>
  <SlaveImage>
    <name>default-image</name>
    <default/>
    <arch>x86_64</arch>
    <basedist>UBUNTU2404</basedist>
    <kernel>DEFAULT</kernel>
    <kernelversion/>
    <initrdmodule>aacraid</initrdmodule>
    <initrdmodule>ahci</initrdmodule>
    <initrdmodule>aic79xx</initrdmodule>
    <initrdmodule>aic7xxx</initrdmodule>
    <initrdmodule>arcmsr</initrdmodule>
    <initrdmodule>hpsa</initrdmodule>
    <initrdmodule>megaraid</initrdmodule>
    <initrdmodule>megaraid_sas</initrdmodule>
    <initrdmodule>mpt3sas</initrdmodule>
    <initrdmodule>mptsas</initrdmodule>
    <initrdmodule>mptscsih</initrdmodule>
    <initrdmodule>mptspi</initrdmodule>
    <initrdmodule>sata_nv</initrdmodule>
    <initrdmodule>sata_sil</initrdmodule>
    <initrdmodule>sata_svw</initrdmodule>
    <initrdmodule>bnx2</initrdmodule>
    <initrdmodule>bnx2x</initrdmodule>
    <initrdmodule>bridge</initrdmodule>
    <initrdmodule>br_netfilter</initrdmodule>
    <initrdmodule>e1000</initrdmodule>
    <initrdmodule>e1000e</initrdmodule>
    <initrdmodule>forcedeth</initrdmodule>
    <initrdmodule>igb</initrdmodule>
    <initrdmodule>igbvf</initrdmodule>
    <initrdmodule>ixgbe</initrdmodule>
    <initrdmodule>ixgbevf</initrdmodule>
    <initrdmodule>i40e</initrdmodule>
    <initrdmodule>tg3</initrdmodule>
    <initrdmodule>hv_netvsc</initrdmodule>
    <initrdmodule>hv_storvsc</initrdmodule>
    <initrdmodule>hv_utils</initrdmodule>
    <initrdmodule>hv_vmbus</initrdmodule>
    <initrdmodule>btrfs</initrdmodule>
    <initrdmodule>jfs</initrdmodule>
    <initrdmodule>nfs</initrdmodule>
    <initrdmodule>nfsv3</initrdmodule>
    <initrdmodule>nfsv4</initrdmodule>
    <initrdmodule>reiserfs</initrdmodule>
    <initrdmodule>xfs</initrdmodule>
    <initrdmodule>udf</initrdmodule>
    <initrdmodule>usbhid</initrdmodule>
    <initrdmodule>dm-persistent-data</initrdmodule>
    <initrdmodule>dm-bio-prison</initrdmodule>
    <initrdmodule>dm-bufio</initrdmodule>
    <initrdmodule>dm-thin-pool</initrdmodule>
    <initrdmodule>nvme</initrdmodule>
    <initrdmodule>isofs</initrdmodule>
    <initrdmodule>bnxt_en</initrdmodule>
    <initrdmodule>bonding</initrdmodule>
    <initrdmodule>hpilo</initrdmodule>
    <initrdmodule>ipmi_si</initrdmodule>
    <initrdmodule>ipmi_ssif</initrdmodule>
    <initrdmodule>ipmi_devintf</initrdmodule>
    <baserpmstore>dist/ubuntu/2404</baserpmstore>
    <cmrpmstore>11.31.1/ubuntu/2404</cmrpmstore>
    <baserpm install="yes" arch="all">po-debconf</baserpm>
    <baserpm install="yes" arch="all">at-spi2-common</baserpm>
    <baserpm install="yes" arch="all">fonts-liberation</baserpm>
    <baserpm install="yes" arch="all">python3-chardet</baserpm>
    <baserpm install="yes" arch="all">libdebhelper-perl</baserpm>
    <baserpm install="yes" arch="all">dh-autoreconf</baserpm>
    <baserpm install="yes" arch="all">python3-cssselect</baserpm>
    <baserpm install="yes" arch="all">libsource-highlight-common</baserpm>
    <baserpm install="yes" arch="all">python3-openssl</baserpm>
    <baserpm install="yes" arch="all">libdata-dump-perl</baserpm>
    <baserpm install="yes" arch="all">python3-pip</baserpm>
    <baserpm install="yes" arch="all">libnet-smtp-ssl-perl</baserpm>
    <baserpm install="yes" arch="all">python-is-python3</baserpm>
    <baserpm install="yes" arch="all">manpages</baserpm>
    <baserpm install="yes" arch="all">python3-html5lib</baserpm>
    <baserpm install="yes" arch="all">fonts-liberation2</baserpm>
    <baserpm install="yes" arch="all">lua-json</baserpm>
    <baserpm install="yes" arch="all">finalrd</baserpm>
    <baserpm install="yes" arch="all">libjson-perl</baserpm>
    <baserpm install="yes" arch="all">python3-jeepney</baserpm>
    <baserpm install="yes" arch="all">libauthen-sasl-perl</baserpm>
    <baserpm install="yes" arch="all">libxml-namespacesupport-perl</baserpm>
    <baserpm install="yes" arch="all">xbitmaps</baserpm>
    <baserpm install="yes" arch="all">geoip-database</baserpm>
    <baserpm install="yes" arch="all">mailutils-common</baserpm>
    <baserpm install="yes" arch="all">shorewall-core</baserpm>
    <baserpm install="yes" arch="all">dh-strip-nondeterminism</baserpm>
    <baserpm install="yes" arch="all">alsa-topology-conf</baserpm>
    <baserpm install="yes" arch="all">ifenslave</baserpm>
    <baserpm install="yes" arch="all">libxml-sax-expat-perl</baserpm>
    <baserpm install="yes" arch="all">python3-jaraco.classes</baserpm>
    <baserpm install="yes" arch="all">libio-socket-inet6-perl</baserpm>
    <baserpm install="yes" arch="all">liblwp-mediatypes-perl</baserpm>
    <baserpm install="yes" arch="all">wireless-regdb</baserpm>
    <baserpm install="yes" arch="all">python3-soupsieve</baserpm>
    <baserpm install="yes" arch="all">shorewall</baserpm>
    <baserpm install="yes" arch="all">libxml-sax-base-perl</baserpm>
    <baserpm install="yes" arch="all">gsasl-common</baserpm>
    <baserpm install="yes" arch="all">libsensors-config</baserpm>
    <baserpm install="yes" arch="all">xfonts-encodings</baserpm>
    <baserpm install="yes" arch="all">ntp</baserpm>
    <baserpm install="yes" arch="all">libatk-wrapper-java</baserpm>
    <baserpm install="yes" arch="all">python3-pyasn1</baserpm>
    <baserpm install="yes" arch="all">python3-importlib-metadata</baserpm>
    <baserpm install="yes" arch="all">sound-theme-freedesktop</baserpm>
    <baserpm install="yes" arch="all">javascript-common</baserpm>
    <baserpm install="yes" arch="all">libhttp-negotiate-perl</baserpm>
    <baserpm install="yes" arch="all">libstring-shellquote-perl</baserpm>
    <baserpm install="yes" arch="all">xfonts-base</baserpm>
    <baserpm install="yes" arch="all">libfile-stripnondeterminism-perl</baserpm>
    <baserpm install="yes" arch="all">libmailtools-perl</baserpm>
    <baserpm install="yes" arch="all">libhtml-format-perl</baserpm>
    <baserpm install="yes" arch="all">libencode-locale-perl</baserpm>
    <baserpm install="yes" arch="all">libalgorithm-merge-perl</baserpm>
    <baserpm install="yes" arch="all">fonts-liberation-sans-narrow</baserpm>
    <baserpm install="yes" arch="all">parallel</baserpm>
    <baserpm install="yes" arch="all">mysql-common</baserpm>
    <baserpm install="yes" arch="all">libio-socket-ssl-perl</baserpm>
    <baserpm install="yes" arch="all">libasound2-data</baserpm>
    <baserpm install="yes" arch="all">liblwp-protocol-https-perl</baserpm>
    <baserpm install="yes" arch="all">gsettings-desktop-schemas</baserpm>
    <baserpm install="yes" arch="all">python3-pkg-resources</baserpm>
    <baserpm install="yes" arch="all">python3-idna</baserpm>
    <baserpm install="yes" arch="all">liburi-perl</baserpm>
    <baserpm install="yes" arch="all">libfile-listing-perl</baserpm>
    <baserpm install="yes" arch="all">python3-dateutil</baserpm>
    <baserpm install="yes" arch="all">alsa-ucm-conf</baserpm>
    <baserpm install="yes" arch="all">python3-six</baserpm>
    <baserpm install="yes" arch="all">cgroup-lite</baserpm>
    <baserpm install="yes" arch="all">autopoint</baserpm>
    <baserpm install="yes" arch="all">python3-webencodings</baserpm>
    <baserpm install="yes" arch="all">cryptsetup-initramfs</baserpm>
    <baserpm install="yes" arch="all">libarchive-zip-perl</baserpm>
    <baserpm install="yes" arch="all">libhttp-daemon-perl</baserpm>
    <baserpm install="yes" arch="all">libhttp-date-perl</baserpm>
    <baserpm install="yes" arch="all">libwww-robotrules-perl</baserpm>
    <baserpm install="yes" arch="all">libalgorithm-diff-perl</baserpm>
    <baserpm install="yes" arch="all">libarchive-cpio-perl</baserpm>
    <baserpm install="yes" arch="all">python3-prettytable</baserpm>
    <baserpm install="yes" arch="all">libsys-hostname-long-perl</baserpm>
    <baserpm install="yes" arch="all">libxml-sax-perl</baserpm>
    <baserpm install="yes" arch="all">adwaita-icon-theme</baserpm>
    <baserpm install="yes" arch="all">libnet-http-perl</baserpm>
    <baserpm install="yes" arch="all">vim-runtime</baserpm>
    <baserpm install="yes" arch="all">python3-contextlib2</baserpm>
    <baserpm install="yes" arch="all">python3-wheel</baserpm>
    <baserpm install="yes" arch="all">xserver-common</baserpm>
    <baserpm install="yes" arch="all">nslcd-utils</baserpm>
    <baserpm install="yes" arch="all">java-common</baserpm>
    <baserpm install="yes" arch="all">debhelper</baserpm>
    <baserpm install="yes" arch="all">python3-bs4</baserpm>
    <baserpm install="yes" arch="all">libhttp-message-perl</baserpm>
    <baserpm install="yes" arch="all">screen-resolution-extra</baserpm>
    <baserpm install="yes" arch="all">libsub-override-perl</baserpm>
    <baserpm install="yes" arch="all">quilt</baserpm>
    <baserpm install="yes" arch="all">libio-html-perl</baserpm>
    <baserpm install="yes" arch="all">ssl-cert</baserpm>
    <baserpm install="yes" arch="all">libtry-tiny-perl</baserpm>
    <baserpm install="yes" arch="all">python3-secretstorage</baserpm>
    <baserpm install="yes" arch="all">python3-blinker</baserpm>
    <baserpm install="yes" arch="all">python3-entrypoints</baserpm>
    <baserpm install="yes" arch="all">libtypes-serialiser-perl</baserpm>
    <baserpm install="yes" arch="all">shorewall-init</baserpm>
    <baserpm install="yes" arch="all">libjs-sphinxdoc</baserpm>
    <baserpm install="yes" arch="all">bsdmainutils</baserpm>
    <baserpm install="yes" arch="all">dpkg-dev</baserpm>
    <baserpm install="yes" arch="all">dkms</baserpm>
    <baserpm install="yes" arch="all">libgtk2.0-common</baserpm>
    <baserpm install="yes" arch="all">python3-xkit</baserpm>
    <baserpm install="yes" arch="all">libtimedate-perl</baserpm>
    <baserpm install="yes" arch="all">language-pack-en-base</baserpm>
    <baserpm install="yes" arch="all">libmail-sendmail-perl</baserpm>
    <baserpm install="yes" arch="all">dns-root-data</baserpm>
    <baserpm install="yes" arch="all">libwww-perl</baserpm>
    <baserpm install="yes" arch="all">intltool</baserpm>
    <baserpm install="yes" arch="all">shorewall6</baserpm>
    <baserpm install="yes" arch="all">python3-zipp</baserpm>
    <baserpm install="yes" arch="all">libgdk-pixbuf2.0-common</baserpm>
    <baserpm install="yes" arch="all">sntp</baserpm>
    <baserpm install="yes" arch="all">autotools-dev</baserpm>
    <baserpm install="yes" arch="all">hicolor-icon-theme</baserpm>
    <baserpm install="yes" arch="all">libhtml-tagset-perl</baserpm>
    <baserpm install="yes" arch="all">humanity-icon-theme</baserpm>
    <baserpm install="no" hwvendor="hp" arch="all">python3-hpilo</baserpm>
    <baserpm install="yes" arch="all">libhttp-cookies-perl</baserpm>
    <baserpm install="yes" arch="all">lto-disabled-list</baserpm>
    <baserpm install="yes" arch="all">manpages-dev</baserpm>
    <baserpm install="yes" arch="all">autoconf</baserpm>
    <baserpm install="yes" arch="all">ubuntu-mono</baserpm>
    <baserpm install="yes" arch="all">libsnmp-base</baserpm>
    <baserpm install="yes" arch="all">ca-certificates-java</baserpm>
    <baserpm install="yes" arch="all">libhtml-form-perl</baserpm>
    <baserpm install="yes" arch="all">libhtml-tree-perl</baserpm>
    <baserpm install="yes" arch="all">python3-more-itertools</baserpm>
    <baserpm install="yes" arch="all">intltool-debian</baserpm>
    <baserpm install="yes" arch="all">fonts-dejavu-core</baserpm>
    <baserpm install="yes" arch="all">python3-keyring</baserpm>
    <baserpm install="yes" arch="all">automake</baserpm>
    <baserpm install="yes" arch="all">libdpkg-perl</baserpm>
    <baserpm install="yes" arch="all">python3-wcwidth</baserpm>
    <baserpm install="yes" arch="all">language-pack-en</baserpm>
    <baserpm install="yes" arch="all">libgtk-3-common</baserpm>
    <baserpm install="yes" arch="all">libtool</baserpm>
    <baserpm install="yes" arch="all">x11-common</baserpm>
    <baserpm install="yes" arch="all">libjs-jquery</baserpm>
    <baserpm install="yes" arch="all">libdebuginfod-common</baserpm>
    <baserpm install="yes" arch="all">fonts-dejavu-extra</baserpm>
    <baserpm install="yes" arch="all">libfont-afm-perl</baserpm>
    <baserpm install="yes" arch="all">libthai-data</baserpm>
    <baserpm install="yes" arch="all">libjs-underscore</baserpm>
    <baserpm install="yes" arch="amd64">python3-cryptography</baserpm>
    <baserpm install="yes" arch="amd64">ntpsec-ntpdig</baserpm>
    <baserpm install="yes" arch="amd64">libcolord2</baserpm>
    <baserpm install="yes" arch="amd64">gcc-13-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">cpp-9</baserpm>
    <baserpm install="yes" arch="amd64">python3-dbus</baserpm>
    <baserpm install="yes" arch="amd64">fdupes</baserpm>
    <baserpm install="yes" arch="amd64">cryptsetup</baserpm>
    <baserpm install="yes" arch="amd64">nfs-kernel-server</baserpm>
    <baserpm install="yes" arch="amd64">libnss-ldapd</baserpm>
    <baserpm install="yes" arch="amd64">libibmad5</baserpm>
    <baserpm install="yes" arch="amd64">libasprintf-dev</baserpm>
    <baserpm install="yes" arch="amd64">libgfortran-11-dev</baserpm>
    <baserpm install="yes" arch="amd64">python3-cffi-backend</baserpm>
    <baserpm install="yes" arch="amd64">lua-filesystem</baserpm>
    <baserpm install="yes" arch="amd64">openjdk-8-jre</baserpm>
    <baserpm install="yes" arch="amd64">libxft2</baserpm>
    <baserpm install="yes" arch="amd64">libibverbs1</baserpm>
    <baserpm install="yes" arch="amd64">libssh2-1t64</baserpm>
    <baserpm install="yes" arch="amd64">libumad2sim0</baserpm>
    <baserpm install="yes" arch="amd64">libdrm-intel1</baserpm>
    <baserpm install="yes" arch="amd64">libjpeg8</baserpm>
    <baserpm install="yes" arch="amd64">vim</baserpm>
    <baserpm install="yes" arch="amd64">systemd</baserpm>
    <baserpm install="yes" arch="amd64">libevent-core-2.1-7t64</baserpm>
    <baserpm install="yes" arch="amd64">libpangocairo-1.0-0</baserpm>
    <baserpm install="yes" arch="amd64">g++-11</baserpm>
    <baserpm install="yes" arch="amd64">libgles2</baserpm>
    <baserpm install="yes" arch="amd64">libgcc-13-dev</baserpm>
    <baserpm install="yes" arch="amd64">libpangoft2-1.0-0</baserpm>
    <baserpm install="yes" arch="amd64">xfonts-utils</baserpm>
    <baserpm install="yes" arch="amd64">libxkbcommon-x11-0</baserpm>
    <baserpm install="yes" arch="amd64">grub-pc-bin</baserpm>
    <baserpm install="yes" arch="amd64">libpulse0</baserpm>
    <baserpm install="yes" arch="amd64">libxinerama1</baserpm>
    <baserpm install="yes" arch="amd64">libllvm18</baserpm>
    <baserpm install="yes" arch="amd64">libxss1</baserpm>
    <baserpm install="yes" arch="amd64">libdrm-radeon1</baserpm>
    <baserpm install="yes" arch="amd64">pkgconf-bin</baserpm>
    <baserpm install="yes" arch="amd64">pv</baserpm>
    <baserpm install="yes" arch="amd64">chrpath</baserpm>
    <baserpm install="yes" arch="amd64">tcl-expect</baserpm>
    <baserpm install="yes" arch="amd64">libalgorithm-diff-xs-perl</baserpm>
    <baserpm install="yes" arch="amd64">libnetfilter-cthelper0</baserpm>
    <baserpm install="yes" arch="amd64">libmp3lame0</baserpm>
    <baserpm install="yes" arch="amd64">dbus-x11</baserpm>
    <baserpm install="yes" arch="amd64">libdeflate0</baserpm>
    <baserpm install="yes" arch="amd64">lldpd</baserpm>
    <baserpm install="yes" arch="amd64">libnl-route-3-200</baserpm>
    <baserpm install="yes" arch="amd64">python3.12-minimal</baserpm>
    <baserpm install="yes" arch="amd64">libsource-highlight4t64</baserpm>
    <baserpm install="yes" arch="amd64">xsltproc</baserpm>
    <baserpm install="yes" arch="amd64">libibumad3</baserpm>
    <baserpm install="yes" arch="amd64">libegl-mesa0</baserpm>
    <baserpm install="yes" arch="amd64">binutils-common</baserpm>
    <baserpm install="yes" arch="amd64">opensm</baserpm>
    <baserpm install="yes" arch="amd64">openssh-server</baserpm>
    <baserpm install="yes" arch="amd64">libzstd1</baserpm>
    <baserpm install="yes" arch="amd64">rsync</baserpm>
    <baserpm install="yes" arch="amd64">libgtk-3-bin</baserpm>
    <baserpm install="yes" arch="amd64">rdma-core</baserpm>
    <baserpm install="yes" arch="amd64">linux-modules-extra-6.8.0-51-generic</baserpm>
    <baserpm install="yes" arch="amd64">g++-9</baserpm>
    <baserpm install="yes" arch="amd64">libopts25</baserpm>
    <baserpm install="yes" arch="amd64">gcc-9-base</baserpm>
    <baserpm install="yes" arch="amd64">gcc-9</baserpm>
    <baserpm install="yes" arch="amd64">binutils</baserpm>
    <baserpm install="yes" arch="amd64">libgtk2.0-bin</baserpm>
    <baserpm install="yes" arch="amd64">libltdl-dev</baserpm>
    <baserpm install="yes" arch="amd64">libtsan2</baserpm>
    <baserpm install="yes" arch="amd64">binutils-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">python3-dev</baserpm>
    <baserpm install="yes" arch="amd64">ibsim-utils</baserpm>
    <baserpm install="yes" arch="amd64">libssl-dev</baserpm>
    <baserpm install="yes" arch="amd64">libnspr4</baserpm>
    <baserpm install="yes" arch="amd64">libx11-xcb1</baserpm>
    <baserpm install="yes" arch="amd64">libipt2</baserpm>
    <baserpm install="yes" arch="amd64">libmpg123-0t64</baserpm>
    <baserpm install="yes" arch="amd64">g++-13-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">gcc</baserpm>
    <baserpm install="yes" arch="amd64">g++-13</baserpm>
    <baserpm install="yes" arch="amd64">libbabeltrace1</baserpm>
    <baserpm install="yes" arch="amd64">libctf-nobfd0</baserpm>
    <baserpm install="yes" arch="amd64">libcc1-0</baserpm>
    <baserpm install="yes" arch="amd64">cryptsetup-bin</baserpm>
    <baserpm install="yes" arch="amd64">libelf1t64</baserpm>
    <baserpm install="yes" arch="amd64">make</baserpm>
    <baserpm install="yes" arch="amd64">ibacm</baserpm>
    <baserpm install="yes" arch="amd64">libxslt1.1</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-shm0</baserpm>
    <baserpm install="yes" arch="amd64">libgl1-amber-dri</baserpm>
    <baserpm install="yes" arch="amd64">unzip</baserpm>
    <baserpm install="yes" arch="amd64">libpcre2-32-0</baserpm>
    <baserpm install="yes" arch="amd64">libgsasl18</baserpm>
    <baserpm install="yes" arch="amd64">gtk-update-icon-cache</baserpm>
    <baserpm install="yes" arch="amd64">libfontenc1</baserpm>
    <baserpm install="yes" arch="amd64">libxtst6</baserpm>
    <baserpm install="yes" arch="amd64">libbison-dev</baserpm>
    <baserpm install="yes" arch="amd64">rdmacm-utils</baserpm>
    <baserpm install="yes" arch="amd64">libtcl8.6</baserpm>
    <baserpm install="yes" arch="amd64">libdapl2</baserpm>
    <baserpm install="yes" arch="amd64">libgfortran5</baserpm>
    <baserpm install="yes" arch="amd64">ntpsec-ntpdate</baserpm>
    <baserpm install="yes" arch="amd64">libvpx9</baserpm>
    <baserpm install="yes" arch="amd64">gcc-11-base</baserpm>
    <baserpm install="yes" arch="amd64">libavahi-common-data</baserpm>
    <baserpm install="yes" arch="amd64">libxmu6</baserpm>
    <baserpm install="yes" arch="amd64">session-migration</baserpm>
    <baserpm install="yes" arch="amd64">bind9-host</baserpm>
    <baserpm install="yes" arch="amd64">libatk-bridge2.0-0t64</baserpm>
    <baserpm install="yes" arch="amd64">groff-base</baserpm>
    <baserpm install="yes" arch="amd64">libwebp7</baserpm>
    <baserpm install="yes" arch="amd64">libexpat1-dev</baserpm>
    <baserpm install="yes" arch="amd64">cpp</baserpm>
    <baserpm install="yes" arch="amd64">libltdl7</baserpm>
    <baserpm install="yes" arch="amd64">libxml-libxml-perl</baserpm>
    <baserpm install="yes" arch="amd64">libcairo2</baserpm>
    <baserpm install="yes" arch="amd64">libpango-1.0-0</baserpm>
    <baserpm install="yes" arch="amd64">libgcc-11-dev</baserpm>
    <baserpm install="yes" arch="amd64">libsensors5</baserpm>
    <baserpm install="yes" arch="amd64">libharfbuzz0b</baserpm>
    <baserpm install="yes" arch="amd64">libdatrie1</baserpm>
    <baserpm install="yes" arch="amd64">libsframe1</baserpm>
    <baserpm install="yes" arch="amd64">libfuse2t64</baserpm>
    <baserpm install="yes" arch="amd64">attr</baserpm>
    <baserpm install="yes" arch="amd64">vdpau-driver-all</baserpm>
    <baserpm install="yes" arch="amd64">grub-efi-amd64-bin</baserpm>
    <baserpm install="yes" arch="amd64">libgssglue1</baserpm>
    <baserpm install="yes" arch="amd64">libbinutils</baserpm>
    <baserpm install="yes" arch="amd64">libllvm17t64</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-render0</baserpm>
    <baserpm install="yes" arch="amd64">gcc-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">libpython3.12-dev</baserpm>
    <baserpm install="yes" arch="amd64">fakeroot</baserpm>
    <baserpm install="yes" arch="amd64">gcc-12-base</baserpm>
    <baserpm install="yes" arch="amd64">nscd</baserpm>
    <baserpm install="yes" arch="amd64">default-jre-headless</baserpm>
    <baserpm install="yes" arch="amd64">python3-ntp</baserpm>
    <baserpm install="yes" arch="amd64">libubsan1</baserpm>
    <baserpm install="yes" arch="amd64">postfix</baserpm>
    <baserpm install="yes" arch="amd64">man-db</baserpm>
    <baserpm install="yes" arch="amd64">libpathplan4</baserpm>
    <baserpm install="yes" arch="amd64">tcl8.6</baserpm>
    <baserpm install="yes" arch="amd64">libhwasan0</baserpm>
    <baserpm install="yes" arch="amd64">tcl</baserpm>
    <baserpm install="yes" arch="amd64">dosfstools</baserpm>
    <baserpm install="yes" arch="amd64">libcanberra0t64</baserpm>
    <baserpm install="yes" arch="amd64">rng-tools-debian</baserpm>
    <baserpm install="yes" arch="amd64">csh</baserpm>
    <baserpm install="yes" arch="amd64">python3-yaml</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-present0</baserpm>
    <baserpm install="yes" arch="amd64">cpp-11</baserpm>
    <baserpm install="yes" arch="amd64">ntpsec</baserpm>
    <baserpm install="yes" arch="amd64">libpq5</baserpm>
    <baserpm install="yes" arch="amd64">isc-dhcp-client</baserpm>
    <baserpm install="yes" arch="amd64">libgd3</baserpm>
    <baserpm install="yes" arch="amd64">libibnetdisc5t64</baserpm>
    <baserpm install="yes" arch="amd64">libpcsclite1</baserpm>
    <baserpm install="yes" arch="amd64">build-essential</baserpm>
    <baserpm install="yes" arch="amd64">libasyncns0</baserpm>
    <baserpm install="yes" arch="amd64">zstd</baserpm>
    <baserpm install="yes" arch="amd64">libllvm19</baserpm>
    <baserpm install="yes" arch="amd64">grub-common</baserpm>
    <baserpm install="yes" arch="amd64">python3</baserpm>
    <baserpm install="yes" arch="amd64">strace</baserpm>
    <baserpm install="yes" arch="amd64">iputils-arping</baserpm>
    <baserpm install="yes" arch="amd64">zlib1g-dev</baserpm>
    <baserpm install="yes" arch="amd64">liblcms2-2</baserpm>
    <baserpm install="yes" arch="amd64">srptools</baserpm>
    <baserpm install="yes" arch="amd64">efivar</baserpm>
    <baserpm install="yes" arch="amd64">libjq1</baserpm>
    <baserpm install="yes" arch="amd64">libnsl2</baserpm>
    <baserpm install="yes" arch="amd64">libegl1</baserpm>
    <baserpm install="yes" arch="amd64">libwayland-server0</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-randr0</baserpm>
    <baserpm install="yes" arch="amd64">fontconfig</baserpm>
    <baserpm install="yes" arch="amd64">libzstd-dev</baserpm>
    <baserpm install="yes" arch="amd64">sysstat</baserpm>
    <baserpm install="yes" arch="amd64">linux-headers-6.8.0-51-generic</baserpm>
    <baserpm install="yes" arch="amd64">libpipeline1</baserpm>
    <baserpm install="yes" arch="amd64">libpython3-dev</baserpm>
    <baserpm install="yes" arch="amd64">libxkbfile1</baserpm>
    <baserpm install="yes" arch="amd64">nfs-common</baserpm>
    <baserpm install="yes" arch="amd64">libavahi-client3</baserpm>
    <baserpm install="yes" arch="amd64">gcc-13-base</baserpm>
    <baserpm install="yes" arch="amd64">libnl-route-3-dev</baserpm>
    <baserpm install="yes" arch="amd64">grub-efi-amd64</baserpm>
    <baserpm install="yes" arch="amd64">libice6</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-glx0</baserpm>
    <baserpm install="yes" arch="amd64">openjdk-11-jre-headless</baserpm>
    <baserpm install="yes" arch="amd64">libwayland-client0</baserpm>
    <baserpm install="yes" arch="amd64">libsm6</baserpm>
    <baserpm install="yes" arch="amd64">python3.12</baserpm>
    <baserpm install="yes" arch="amd64">swig4.1</baserpm>
    <baserpm install="yes" arch="amd64">openjdk-21-jre-headless</baserpm>
    <baserpm install="yes" arch="amd64">libmpc3</baserpm>
    <baserpm install="yes" arch="amd64">libgbm1</baserpm>
    <baserpm install="yes" arch="amd64">libjansson4</baserpm>
    <baserpm install="yes" arch="amd64">sshpass</baserpm>
    <baserpm install="yes" arch="amd64">libgl1</baserpm>
    <baserpm install="yes" arch="amd64">libipsec-mb1</baserpm>
    <baserpm install="yes" arch="amd64">libpci3</baserpm>
    <baserpm install="yes" arch="amd64">libfl-dev</baserpm>
    <baserpm install="yes" arch="amd64">libgdk-pixbuf2.0-0</baserpm>
    <baserpm install="yes" arch="amd64">libopensm9</baserpm>
    <baserpm install="yes" arch="amd64">gettext</baserpm>
    <baserpm install="yes" arch="amd64">net-tools</baserpm>
    <baserpm install="yes" arch="amd64">libxcvt0</baserpm>
    <baserpm install="yes" arch="amd64">htop</baserpm>
    <baserpm install="yes" arch="amd64">libpkgconf3</baserpm>
    <baserpm install="yes" arch="amd64">libgomp1</baserpm>
    <baserpm install="yes" arch="amd64">g++-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">libctf0</baserpm>
    <baserpm install="yes" arch="amd64">libvorbisfile3</baserpm>
    <baserpm install="yes" arch="amd64">libdrm-amdgpu1</baserpm>
    <baserpm install="yes" arch="amd64">mesa-vdpau-drivers</baserpm>
    <baserpm install="yes" arch="amd64">libkyotocabinet16v5</baserpm>
    <baserpm install="yes" arch="amd64">python3-coverage</baserpm>
    <baserpm install="yes" arch="amd64">libsndfile1</baserpm>
    <baserpm install="yes" arch="amd64">libjudydebian1</baserpm>
    <baserpm install="yes" arch="amd64">libxpm4</baserpm>
    <baserpm install="yes" arch="amd64">libefisec1t64</baserpm>
    <baserpm install="yes" arch="amd64">lua-bit32</baserpm>
    <baserpm install="yes" arch="amd64">pigz</baserpm>
    <baserpm install="yes" arch="amd64">dapl2-utils</baserpm>
    <baserpm install="yes" arch="amd64">libmnl-dev</baserpm>
    <baserpm install="yes" arch="amd64">python3.12-dev</baserpm>
    <baserpm install="yes" arch="amd64">libclone-perl</baserpm>
    <baserpm install="yes" arch="amd64">libasan8</baserpm>
    <baserpm install="yes" arch="amd64">ibverbs-providers</baserpm>
    <baserpm install="yes" arch="amd64">keyutils</baserpm>
    <baserpm install="yes" arch="amd64">libgprofng0</baserpm>
    <baserpm install="yes" arch="amd64">swig</baserpm>
    <baserpm install="yes" arch="amd64">perl-openssl-defaults</baserpm>
    <baserpm install="yes" arch="amd64">liblua5.1-0</baserpm>
    <baserpm install="yes" arch="amd64">tk</baserpm>
    <baserpm install="yes" arch="amd64">libhtml-parser-perl</baserpm>
    <baserpm install="yes" arch="amd64">libaio1t64</baserpm>
    <baserpm install="yes" arch="amd64">libpcap0.8t64</baserpm>
    <baserpm install="yes" arch="amd64">grub2-common</baserpm>
    <baserpm install="yes" arch="amd64">libgettextpo0</baserpm>
    <baserpm install="yes" arch="amd64">libibumad-dev</baserpm>
    <baserpm install="yes" arch="amd64">libfile-fcntllock-perl</baserpm>
    <baserpm install="yes" arch="amd64">libtdb1</baserpm>
    <baserpm install="yes" arch="amd64">libavahi-common3</baserpm>
    <baserpm install="yes" arch="amd64">libosmcomp5</baserpm>
    <baserpm install="yes" arch="amd64">jq</baserpm>
    <baserpm install="yes" arch="amd64">lsof</baserpm>
    <baserpm install="yes" arch="amd64">libgail-common</baserpm>
    <baserpm install="yes" arch="amd64">python3-gi</baserpm>
    <baserpm install="yes" arch="amd64">libdebuginfod1t64</baserpm>
    <baserpm install="yes" arch="amd64">mstflint</baserpm>
    <baserpm install="yes" arch="amd64">libxaw7</baserpm>
    <baserpm install="yes" arch="amd64">libmysqlclient-dev</baserpm>
    <baserpm install="yes" arch="amd64">libitm1</baserpm>
    <baserpm install="yes" arch="amd64">libdbd-mysql-perl</baserpm>
    <baserpm install="yes" arch="amd64">libnss3</baserpm>
    <baserpm install="yes" arch="amd64">libdbi-perl</baserpm>
    <baserpm install="yes" arch="amd64">bind9-dnsutils</baserpm>
    <baserpm install="yes" arch="amd64">libflac12t64</baserpm>
    <baserpm install="yes" arch="amd64">libevent-2.1-7t64</baserpm>
    <baserpm install="yes" arch="amd64">m4</baserpm>
    <baserpm install="yes" arch="amd64">libibdm1</baserpm>
    <baserpm install="yes" arch="amd64">libogg0</baserpm>
    <baserpm install="yes" arch="amd64">librsvg2-2</baserpm>
    <baserpm install="yes" arch="amd64">bc</baserpm>
    <baserpm install="yes" arch="amd64">libfontconfig1</baserpm>
    <baserpm install="yes" arch="amd64">libcups2t64</baserpm>
    <baserpm install="yes" arch="amd64">libxshmfence1</baserpm>
    <baserpm install="yes" arch="amd64">ibverbs-utils</baserpm>
    <baserpm install="yes" arch="amd64">libjsoncpp25</baserpm>
    <baserpm install="yes" arch="amd64">libxrandr2</baserpm>
    <baserpm install="yes" arch="amd64">cpp-13</baserpm>
    <baserpm install="yes" arch="amd64">gcc-12</baserpm>
    <baserpm install="yes" arch="amd64">libtsan0</baserpm>
    <baserpm install="yes" arch="amd64">libatomic1</baserpm>
    <baserpm install="yes" arch="amd64">libatasmart4</baserpm>
    <baserpm install="yes" arch="amd64">libtiff6</baserpm>
    <baserpm install="yes" arch="amd64">libcairo-gobject2</baserpm>
    <baserpm install="yes" arch="amd64">libnuma-dev</baserpm>
    <baserpm install="yes" arch="amd64">libonig5</baserpm>
    <baserpm install="yes" arch="amd64">libboost-filesystem1.83.0</baserpm>
    <baserpm install="yes" arch="amd64">libsctp1</baserpm>
    <baserpm install="yes" arch="amd64">libxfixes3</baserpm>
    <baserpm install="yes" arch="amd64">libpython3.12-stdlib</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-xkb1</baserpm>
    <baserpm install="yes" arch="amd64">gfortran-13</baserpm>
    <baserpm install="yes" arch="amd64">open-iscsi</baserpm>
    <baserpm install="yes" arch="amd64">libisns0t64</baserpm>
    <baserpm install="yes" arch="amd64">ldap-utils</baserpm>
    <baserpm install="yes" arch="amd64">libepoxy0</baserpm>
    <baserpm install="yes" arch="amd64">ifupdown</baserpm>
    <baserpm install="yes" arch="amd64">libpam-ldapd</baserpm>
    <baserpm install="yes" arch="amd64">genders</baserpm>
    <baserpm install="yes" arch="amd64">libmuparser2v5</baserpm>
    <baserpm install="yes" arch="amd64">linux-tools-6.8.0-51-generic</baserpm>
    <baserpm install="yes" arch="amd64">bridge-utils</baserpm>
    <baserpm install="yes" arch="amd64">x11-xkb-utils</baserpm>
    <baserpm install="yes" arch="amd64">libcrypt-dev</baserpm>
    <baserpm install="yes" arch="amd64">libosmvendor5</baserpm>
    <baserpm install="yes" arch="amd64">libgvpr2</baserpm>
    <baserpm install="yes" arch="amd64">dctrl-tools</baserpm>
    <baserpm install="yes" arch="amd64">libgfortran-9-dev</baserpm>
    <baserpm install="yes" arch="amd64">bind9</baserpm>
    <baserpm install="yes" arch="amd64">libvdpau1</baserpm>
    <baserpm install="yes" arch="amd64">gcc-11</baserpm>
    <baserpm install="yes" arch="amd64">libopus0</baserpm>
    <baserpm install="yes" arch="amd64">psmisc</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-shape0</baserpm>
    <baserpm install="yes" arch="amd64">ncal</baserpm>
    <baserpm install="yes" arch="amd64">libasound2t64</baserpm>
    <baserpm install="yes" arch="amd64">libnet-ssleay-perl</baserpm>
    <baserpm install="yes" arch="amd64">xxhash</baserpm>
    <baserpm install="yes" arch="amd64">libfl2</baserpm>
    <baserpm install="yes" arch="amd64">libc-devtools</baserpm>
    <baserpm install="yes" arch="amd64">libxxhash0</baserpm>
    <baserpm install="yes" arch="amd64">infiniband-diags</baserpm>
    <baserpm install="yes" arch="amd64">ibutils</baserpm>
    <baserpm install="yes" arch="amd64">liblsan0</baserpm>
    <baserpm install="yes" arch="amd64">libgdk-pixbuf-2.0-0</baserpm>
    <baserpm install="yes" arch="amd64">libidn12</baserpm>
    <baserpm install="yes" arch="amd64">libnuma1</baserpm>
    <baserpm install="yes" arch="amd64">libcdt5</baserpm>
    <baserpm install="yes" arch="amd64">libgtk2.0-0t64</baserpm>
    <baserpm install="yes" arch="amd64">x11-utils</baserpm>
    <baserpm install="yes" arch="amd64">libnfsidmap1</baserpm>
    <baserpm install="yes" arch="amd64">libgtk-3-0t64</baserpm>
    <baserpm install="yes" arch="amd64">libtk8.6</baserpm>
    <baserpm install="yes" arch="amd64">libxkbcommon0</baserpm>
    <baserpm install="yes" arch="amd64">dwz</baserpm>
    <baserpm install="yes" arch="amd64">tcpdump</baserpm>
    <baserpm install="yes" arch="amd64">pkexec</baserpm>
    <baserpm install="yes" arch="amd64">libmysqlclient21</baserpm>
    <baserpm install="yes" arch="amd64">libmailutils9t64</baserpm>
    <baserpm install="yes" arch="amd64">gfortran-13-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">libgts-0.7-5t64</baserpm>
    <baserpm install="yes" arch="amd64">libdrm-nouveau2</baserpm>
    <baserpm install="yes" arch="amd64">libvorbisenc2</baserpm>
    <baserpm install="yes" arch="amd64">socat</baserpm>
    <baserpm install="yes" arch="amd64">libc6-dbg</baserpm>
    <baserpm install="yes" arch="amd64">libgl1-mesa-dri</baserpm>
    <baserpm install="yes" arch="amd64">perftest</baserpm>
    <baserpm install="yes" arch="amd64">rpcbind</baserpm>
    <baserpm install="yes" arch="amd64">libstdc++-13-dev</baserpm>
    <baserpm install="yes" arch="amd64">flex</baserpm>
    <baserpm install="yes" arch="amd64">libpython3.12t64</baserpm>
    <baserpm install="yes" arch="amd64">libxml-parser-perl</baserpm>
    <baserpm install="yes" arch="amd64">libxxf86dga1</baserpm>
    <baserpm install="yes" arch="amd64">libxi6</baserpm>
    <baserpm install="yes" arch="amd64">libc-dev-bin</baserpm>
    <baserpm install="yes" arch="amd64">mailutils</baserpm>
    <baserpm install="yes" arch="amd64">stress-ng</baserpm>
    <baserpm install="yes" arch="amd64">fontconfig-config</baserpm>
    <baserpm install="yes" arch="amd64">mesa-libgallium</baserpm>
    <baserpm install="yes" arch="amd64">cpp-12</baserpm>
    <baserpm install="yes" arch="amd64">libwayland-egl1</baserpm>
    <baserpm install="yes" arch="amd64">libpixman-1-0</baserpm>
    <baserpm install="yes" arch="amd64">libgenders0</baserpm>
    <baserpm install="yes" arch="amd64">debugedit</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-xfixes0</baserpm>
    <baserpm install="yes" arch="amd64">libvorbis0a</baserpm>
    <baserpm install="yes" arch="amd64">libgraphite2-3</baserpm>
    <baserpm install="yes" arch="amd64">libavahi-glib1</baserpm>
    <baserpm install="yes" arch="amd64">lua-bitop</baserpm>
    <baserpm install="yes" arch="amd64">libgdk-pixbuf-xlib-2.0-0</baserpm>
    <baserpm install="yes" arch="amd64">smartmontools</baserpm>
    <baserpm install="yes" arch="amd64">libvulkan1</baserpm>
    <baserpm install="yes" arch="amd64">graphviz</baserpm>
    <baserpm install="yes" arch="amd64">python3-lxml</baserpm>
    <baserpm install="yes" arch="amd64">thin-provisioning-tools</baserpm>
    <baserpm install="yes" arch="amd64">bzip2</baserpm>
    <baserpm install="yes" arch="amd64">libgettextpo-dev</baserpm>
    <baserpm install="yes" arch="amd64">libibmad-dev</baserpm>
    <baserpm install="yes" arch="amd64">libgfortran-13-dev</baserpm>
    <baserpm install="yes" arch="amd64">lua5.1</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-dri2-0</baserpm>
    <baserpm install="yes" arch="amd64">tk8.6</baserpm>
    <baserpm install="yes" arch="amd64">libgc1</baserpm>
    <baserpm install="yes" arch="amd64">libxfont2</baserpm>
    <baserpm install="yes" arch="amd64">pkg-config</baserpm>
    <baserpm install="yes" arch="amd64">libasan5</baserpm>
    <baserpm install="yes" arch="amd64">libxt6t64</baserpm>
    <baserpm install="yes" arch="amd64">libjbig0</baserpm>
    <baserpm install="yes" arch="amd64">libsocket6-perl</baserpm>
    <baserpm install="yes" arch="amd64">libgcc-9-dev</baserpm>
    <baserpm install="yes" arch="amd64">linux-libc-dev</baserpm>
    <baserpm install="yes" arch="amd64">libical3t64</baserpm>
    <baserpm install="yes" arch="amd64">libdconf1</baserpm>
    <baserpm install="yes" arch="amd64">switcheroo-control</baserpm>
    <baserpm install="yes" arch="amd64">g++</baserpm>
    <baserpm install="yes" arch="amd64">libpsm-infinipath1-dev</baserpm>
    <baserpm install="yes" arch="amd64">libglvnd0</baserpm>
    <baserpm install="yes" arch="amd64">xserver-xorg-core</baserpm>
    <baserpm install="yes" arch="amd64">libthai0</baserpm>
    <baserpm install="yes" arch="amd64">libtirpc-dev</baserpm>
    <baserpm install="yes" arch="amd64">bison</baserpm>
    <baserpm install="yes" arch="amd64">libxrender1</baserpm>
    <baserpm install="yes" arch="amd64">libstdc++-11-dev</baserpm>
    <baserpm install="yes" arch="amd64">libgif7</baserpm>
    <baserpm install="yes" arch="amd64">cpp-13-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">libsnmp40t64</baserpm>
    <baserpm install="yes" arch="amd64">libgail18t64</baserpm>
    <baserpm install="yes" arch="amd64">libxxf86vm1</baserpm>
    <baserpm install="yes" arch="amd64">systemd-coredump</baserpm>
    <baserpm install="yes" arch="amd64">liblab-gamut1</baserpm>
    <baserpm install="yes" arch="amd64">patchutils</baserpm>
    <baserpm install="yes" arch="amd64">xcvt</baserpm>
    <baserpm install="yes" arch="amd64">gfortran-11</baserpm>
    <baserpm install="yes" arch="amd64">libntlm0</baserpm>
    <baserpm install="yes" arch="amd64">librsvg2-common</baserpm>
    <baserpm install="yes" arch="amd64">gfortran-9</baserpm>
    <baserpm install="yes" arch="amd64">lua-lpeg</baserpm>
    <baserpm install="yes" arch="amd64">nslcd</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-dri3-0</baserpm>
    <baserpm install="yes" arch="amd64">libxcb-sync1</baserpm>
    <baserpm install="yes" arch="amd64">libglapi-mesa</baserpm>
    <baserpm install="yes" arch="amd64">libquadmath0</baserpm>
    <baserpm install="yes" arch="amd64">libcgroup2</baserpm>
    <baserpm install="yes" arch="amd64">libxcomposite1</baserpm>
    <baserpm install="yes" arch="amd64">libisl23</baserpm>
    <baserpm install="yes" arch="amd64">libann0</baserpm>
    <baserpm install="yes" arch="amd64">libasan6</baserpm>
    <baserpm install="yes" arch="amd64">python3-libxml2</baserpm>
    <baserpm install="yes" arch="amd64">lua-posix</baserpm>
    <baserpm install="yes" arch="amd64">python3-zstandard</baserpm>
    <baserpm install="yes" arch="amd64">gcc-13</baserpm>
    <baserpm install="yes" arch="amd64">libxdamage1</baserpm>
    <baserpm install="yes" arch="amd64">cgroup-tools</baserpm>
    <baserpm install="yes" arch="amd64">bind9-utils</baserpm>
    <baserpm install="yes" arch="amd64">libevent-pthreads-2.1-7t64</baserpm>
    <baserpm install="yes" arch="amd64">libatspi2.0-0t64</baserpm>
    <baserpm install="yes" arch="amd64">dconf-gsettings-backend</baserpm>
    <baserpm install="yes" arch="amd64">libglx0</baserpm>
    <baserpm install="yes" arch="amd64">gfortran</baserpm>
    <baserpm install="yes" arch="amd64">libasprintf0v5</baserpm>
    <baserpm install="yes" arch="amd64">libgcc-12-dev</baserpm>
    <baserpm install="yes" arch="amd64">mesa-vulkan-drivers</baserpm>
    <baserpm install="yes" arch="amd64">librdmacm1t64</baserpm>
    <baserpm install="yes" arch="amd64">libc6-dev</baserpm>
    <baserpm install="yes" arch="amd64">libtirpc3t64</baserpm>
    <baserpm install="yes" arch="amd64">libstdc++-9-dev</baserpm>
    <baserpm install="yes" arch="amd64">diffstat</baserpm>
    <baserpm install="yes" arch="amd64">libnl-3-dev</baserpm>
    <baserpm install="yes" arch="amd64">libcommon-sense-perl</baserpm>
    <baserpm install="yes" arch="amd64">libxv1</baserpm>
    <baserpm install="yes" arch="amd64">libcryptsetup12</baserpm>
    <baserpm install="yes" arch="amd64">libnsl-dev</baserpm>
    <baserpm install="yes" arch="amd64">libcgraph6</baserpm>
    <baserpm install="yes" arch="amd64">cpp-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">pciutils</baserpm>
    <baserpm install="yes" arch="amd64">guile-3.0-libs</baserpm>
    <baserpm install="yes" arch="amd64">linux-image-6.8.0-51-generic</baserpm>
    <baserpm install="yes" arch="amd64">rpcsvc-proto</baserpm>
    <baserpm install="yes" arch="amd64">libgdk-pixbuf2.0-bin</baserpm>
    <baserpm install="yes" arch="amd64">libpciaccess0</baserpm>
    <baserpm install="yes" arch="amd64">libgeoip1t64</baserpm>
    <baserpm install="yes" arch="amd64">libatk1.0-0t64</baserpm>
    <baserpm install="yes" arch="amd64">gdb</baserpm>
    <baserpm install="yes" arch="amd64">libyaml-0-2</baserpm>
    <baserpm install="yes" arch="amd64">xterm</baserpm>
    <baserpm install="yes" arch="amd64">libglx-mesa0</baserpm>
    <baserpm install="yes" arch="amd64">guile-2.2-libs</baserpm>
    <baserpm install="yes" arch="amd64">openjdk-8-jre-headless</baserpm>
    <baserpm install="yes" arch="amd64">libxcursor1</baserpm>
    <baserpm install="yes" arch="amd64">libjpeg-turbo8</baserpm>
    <baserpm install="yes" arch="amd64">libatk-wrapper-java-jni</baserpm>
    <baserpm install="yes" arch="amd64">libgvc6</baserpm>
    <baserpm install="yes" arch="amd64">gfortran-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">libgts-bin</baserpm>
    <baserpm install="yes" arch="amd64">dconf-service</baserpm>
    <baserpm install="yes" arch="amd64">nvme-cli</baserpm>
    <baserpm install="yes" arch="amd64">libpsm-infinipath1</baserpm>
    <baserpm install="yes" arch="amd64">libfakeroot</baserpm>
    <baserpm install="yes" arch="amd64">at-spi2-core</baserpm>
    <baserpm install="yes" arch="amd64">linux-modules-6.8.0-51-generic</baserpm>
    <baserpm install="yes" arch="amd64">libjson-xs-perl</baserpm>
    <baserpm install="yes" arch="amd64">libboost-regex1.83.0</baserpm>
    <baserpm install="yes" arch="amd64">gdbserver</baserpm>
    <baserpm install="yes" arch="amd64">libunistring5</baserpm>
    <baserpm install="yes" arch="amd64">pkgconf</baserpm>
    <baserpm install="yes" arch="amd64">expect</baserpm>
    <baserpm install="yes" arch="amd64">libwayland-cursor0</baserpm>
    <baserpm install="yes" arch="amd64">isc-dhcp-common</baserpm>
    <cmrpm install="yes" arch="all">cm-config-ldap-client</cmrpm>
    <cmrpm install="yes" arch="all">cm-slave</cmrpm>
    <cmrpm install="yes" arch="all">cmdaemon-pythoncm</cmrpm>
    <cmrpm install="yes" arch="all">cm-bios-tools</cmrpm>
    <cmrpm install="yes" arch="all">cm-apt-conf-image</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-dhclient</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-nfsclient</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-apt-cuda</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-syslog-slave</cmrpm>
    <cmrpm install="yes" arch="all">cm-mysql++-devel</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-limits</cmrpm>
    <cmrpm install="yes" arch="all">cm-shorewall-config</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-systemd</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-sysctl-slave</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-grub-slave</cmrpm>
    <cmrpm install="yes" arch="all">cluster-tools-slave</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-apt</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-cm</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-man</cmrpm>
    <cmrpm install="yes" arch="all">cm-modules-init-client</cmrpm>
    <cmrpm install="yes" arch="all">cmburn-slave</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-ssh-slave</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-gmp</cmrpm>
    <cmrpm install="yes" arch="amd64">cmdaemon-remotecm</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-sedutil</cmrpm>
    <cmrpm install="yes" arch="amd64">lua5.1-tcl2lua</cmrpm>
    <cmrpm install="yes" arch="amd64">cuda-dcgm-libs</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-ipmitool</cmrpm>
    <cmrpm install="yes" arch="amd64">openldap-servers</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-nvfwupd</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-libprometheus</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-ipxe-slave</cmrpm>
    <cmrpm install="yes" arch="amd64">cmdaemon</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-confuse</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-prs</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-modules</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-libpam</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-mysql++</cmrpm>
    <cmrpm install="yes" arch="amd64">pdsh</cmrpm>
    <cmrpm install="yes" arch="amd64">cuda-dcgm-nvvs</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-python3</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-boost</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-mariadb-libs</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-atftp-server</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-sdparm</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-busybox</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-luajit</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-openvpn</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-freeipmi</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-gcc</cmrpm>
    <cmrpm install="yes" arch="amd64">lmod</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-lshw</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-python312</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-rsync</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-config-os-arch</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-dhcp</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-curl</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-mpfr</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-openssl</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-initramfs-tools-image</cmrpm>
    <cmrpm install="yes" arch="amd64">net-snmp-recent</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-lua</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-mpc</cmrpm>
    <cmrpm install="yes" arch="amd64">cuda-dcgm</cmrpm>
    <ExtraPackageGroup name="default" install="yes" media="yes">
      <baserpm install="yes" arch="amd64">libhttp-parser2.9</baserpm>
      <baserpm install="yes" arch="amd64">libhttp-parser-dev</baserpm>
      <baserpm install="yes" arch="amd64">libjwt2</baserpm>
      <baserpm install="yes" arch="amd64">libb64-0d</baserpm>
      <baserpm install="yes" arch="all">dkms</baserpm>
      <baserpm install="yes" arch="amd64">libnvidia-cfg1-580</baserpm>
      <baserpm install="yes" arch="all">libnvidia-common-580</baserpm>
      <baserpm install="yes" arch="amd64">libnvidia-compute-580</baserpm>
      <baserpm install="yes" arch="amd64">libnvidia-decode-580</baserpm>
      <baserpm install="yes" arch="amd64">libnvidia-egl-gbm1</baserpm>
      <baserpm install="yes" arch="amd64">libnvidia-egl-wayland1</baserpm>
      <baserpm install="yes" arch="amd64">libnvidia-egl-xcb1</baserpm>
      <baserpm install="yes" arch="amd64">libnvidia-egl-xlib1</baserpm>
      <baserpm install="yes" arch="amd64">libnvidia-encode-580</baserpm>
      <baserpm install="yes" arch="amd64">libnvidia-extra-580</baserpm>
      <baserpm install="yes" arch="amd64">libnvidia-fbc1-580</baserpm>
      <baserpm install="yes" arch="amd64">libnvidia-gl-580</baserpm>
      <baserpm install="yes" arch="amd64">libnvidia-gpucomp-580</baserpm>
      <baserpm install="yes" arch="amd64">libnvidia-nscq</baserpm>
      <baserpm install="yes" arch="amd64">libnvsdm</baserpm>
      <baserpm install="yes" arch="amd64">libxnvctrl0</baserpm>
      <baserpm install="yes" arch="amd64">nvidia-dkms-580-open</baserpm>
      <baserpm install="yes" arch="amd64">nvidia-driver-580-open</baserpm>
      <baserpm install="yes" arch="amd64">nvidia-fabricmanager</baserpm>
      <baserpm install="yes" arch="amd64">nvidia-firmware-580</baserpm>
      <baserpm install="yes" arch="amd64">nvidia-imex</baserpm>
      <baserpm install="yes" arch="amd64">nvidia-kernel-common-580</baserpm>
      <baserpm install="yes" arch="amd64">nvidia-kernel-source-580-open</baserpm>
      <baserpm install="yes" arch="amd64">nvidia-modprobe</baserpm>
      <baserpm install="yes" arch="amd64">nvidia-open-580</baserpm>
      <baserpm install="yes" arch="amd64">nvidia-persistenced</baserpm>
      <baserpm install="yes" arch="amd64">nvidia-settings</baserpm>
      <baserpm install="yes" arch="amd64">xserver-xorg-video-nvidia-580</baserpm>
      <baserpmstore>packagegroups/default</baserpmstore>
      <cmrpmstore>packagegroups/default</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="cuda" install="no" media="yes">
      <baserpm install="yes" arch="all">adwaita-icon-theme</baserpm>
      <baserpm install="yes" arch="amd64">at-spi2-core</baserpm>
      <baserpm install="yes" arch="all">colord-data</baserpm>
      <baserpm install="yes" arch="amd64">colord</baserpm>
      <baserpm install="yes" arch="amd64">dconf-gsettings-backend</baserpm>
      <baserpm install="yes" arch="amd64">dconf-service</baserpm>
      <baserpm install="yes" arch="all">glib-networking-common</baserpm>
      <baserpm install="yes" arch="amd64">glib-networking-services</baserpm>
      <baserpm install="yes" arch="amd64">glib-networking</baserpm>
      <baserpm install="yes" arch="all">gsettings-desktop-schemas</baserpm>
      <baserpm install="yes" arch="all">humanity-icon-theme</baserpm>
      <baserpm install="yes" arch="amd64">libatk-bridge2.0-0t64</baserpm>
      <baserpm install="yes" arch="amd64">libatspi2.0-0t64</baserpm>
      <baserpm install="yes" arch="amd64">libboost-filesystem1.83.0</baserpm>
      <baserpm install="yes" arch="amd64">libboost-system1.83.0</baserpm>
      <baserpm install="yes" arch="amd64">libcairo-gobject2</baserpm>
      <baserpm install="yes" arch="amd64">libcolord2</baserpm>
      <baserpm install="yes" arch="amd64">libcolorhug2</baserpm>
      <baserpm install="yes" arch="amd64">libdconf1</baserpm>
      <baserpm install="yes" arch="amd64">libegl-mesa0</baserpm>
      <baserpm install="yes" arch="amd64">libepoxy0</baserpm>
      <baserpm install="yes" arch="amd64">libexif12</baserpm>
      <baserpm install="yes" arch="amd64">libgbm1</baserpm>
      <baserpm install="yes" arch="amd64">libgphoto2-6t64</baserpm>
      <baserpm install="yes" arch="all">libgphoto2-l10n</baserpm>
      <baserpm install="yes" arch="amd64">libgphoto2-port12t64</baserpm>
      <baserpm install="yes" arch="amd64">libgtk-3-0t64</baserpm>
      <baserpm install="yes" arch="amd64">libgtk-3-bin</baserpm>
      <baserpm install="yes" arch="all">libgtk-3-common</baserpm>
      <baserpm install="yes" arch="amd64">libgudev-1.0-0</baserpm>
      <baserpm install="yes" arch="amd64">libgusb2</baserpm>
      <baserpm install="yes" arch="amd64">libieee1284-3t64</baserpm>
      <baserpm install="yes" arch="amd64">libjson-glib-1.0-0</baserpm>
      <baserpm install="yes" arch="all">libjson-glib-1.0-common</baserpm>
      <baserpm install="yes" arch="amd64">libprotobuf-lite32t64</baserpm>
      <baserpm install="yes" arch="amd64">libproxy1v5</baserpm>
      <baserpm install="yes" arch="amd64">librest-1.0-0</baserpm>
      <baserpm install="yes" arch="amd64">librsvg2-2</baserpm>
      <baserpm install="yes" arch="amd64">librsvg2-common</baserpm>
      <baserpm install="yes" arch="all">libsane-common</baserpm>
      <baserpm install="yes" arch="amd64">libsoup-gnome-2.4-1</baserpm>
      <baserpm install="yes" arch="amd64">libsoup-2.4-1</baserpm>
      <baserpm install="yes" arch="amd64">libwayland-client0</baserpm>
      <baserpm install="yes" arch="amd64">libwayland-cursor0</baserpm>
      <baserpm install="yes" arch="amd64">libwayland-server0</baserpm>
      <baserpm install="yes" arch="amd64">libxcb-xfixes0</baserpm>
      <baserpm install="yes" arch="amd64">libxkbcommon0</baserpm>
      <baserpm install="yes" arch="all">ubuntu-mono</baserpm>
      <baserpm install="yes" arch="amd64">libcapnp-1.0.1</baserpm>
      <baserpm install="yes" arch="amd64">libmircore2t64</baserpm>
      <baserpm install="yes" arch="amd64">acl</baserpm>
      <baserpm install="yes" arch="amd64">avahi-daemon</baserpm>
      <baserpm install="yes" arch="amd64">ipp-usb</baserpm>
      <baserpm install="yes" arch="amd64">libavahi-core7</baserpm>
      <baserpm install="yes" arch="amd64">libdaemon0</baserpm>
      <baserpm install="yes" arch="amd64">libegl1</baserpm>
      <baserpm install="yes" arch="amd64">libgl1-mesa-dri</baserpm>
      <baserpm install="yes" arch="amd64">libglapi-mesa</baserpm>
      <baserpm install="yes" arch="amd64">libglx-mesa0</baserpm>
      <baserpm install="yes" arch="amd64">libnss-mdns</baserpm>
      <baserpm install="yes" arch="amd64">libopenjp2-7</baserpm>
      <baserpm install="yes" arch="amd64">libpoppler-glib8t64</baserpm>
      <baserpm install="yes" arch="amd64">libpoppler134</baserpm>
      <baserpm install="yes" arch="amd64">libsane1</baserpm>
      <baserpm install="yes" arch="all">libsnmp-base</baserpm>
      <baserpm install="yes" arch="amd64">libsnmp40t64</baserpm>
      <baserpm install="yes" arch="all">libsoup2.4-common</baserpm>
      <baserpm install="yes" arch="all">poppler-data</baserpm>
      <baserpm install="yes" arch="amd64">sane-airscan</baserpm>
      <baserpm install="yes" arch="amd64">sane-utils</baserpm>
      <baserpm install="yes" arch="all">update-inetd</baserpm>
      <cmrpm install="yes" arch="amd64">cuda-dcgm</cmrpm>
      <cmrpm install="yes" arch="amd64">cuda-dcgm-nvvs</cmrpm>
      <baserpmstore>packagegroups/cuda</baserpmstore>
      <cmrpmstore>packagegroups/cuda</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="doca_ofed_2.9.3" install="no" media="yes">
      <package-no>ibsim-utils</package-no>
      <package-no>ibutils</package-no>
      <package-no>libumad2sim0</package-no>
      <baserpm install="yes" arch="amd64">doca-ofed</baserpm>
      <baserpm install="yes" arch="amd64">dpcp</baserpm>
      <baserpm install="yes" arch="amd64">hcoll</baserpm>
      <baserpm install="yes" arch="amd64">ibacm</baserpm>
      <baserpm install="yes" arch="amd64">ibarr</baserpm>
      <baserpm install="yes" arch="amd64">ibdump</baserpm>
      <baserpm install="yes" arch="amd64">ibsim</baserpm>
      <baserpm install="yes" arch="all">ibsim-doc</baserpm>
      <baserpm install="yes" arch="amd64">ibutils2</baserpm>
      <baserpm install="yes" arch="amd64">ibverbs-providers</baserpm>
      <baserpm install="yes" arch="amd64">ibverbs-utils</baserpm>
      <baserpm install="yes" arch="amd64">infiniband-diags</baserpm>
      <baserpm install="yes" arch="all">iser-dkms</baserpm>
      <baserpm install="yes" arch="all">isert-dkms</baserpm>
      <baserpm install="yes" arch="all">kernel-mft-dkms</baserpm>
      <baserpm install="yes" arch="amd64">knem</baserpm>
      <baserpm install="yes" arch="all">knem-dkms</baserpm>
      <baserpm install="yes" arch="amd64">libibmad-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibmad5</baserpm>
      <baserpm install="yes" arch="amd64">libibnetdisc5</baserpm>
      <baserpm install="yes" arch="amd64">libibumad-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibumad3</baserpm>
      <baserpm install="yes" arch="amd64">libibverbs-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibverbs1</baserpm>
      <baserpm install="yes" arch="amd64">libopensm</baserpm>
      <baserpm install="yes" arch="amd64">libopensm-devel</baserpm>
      <baserpm install="yes" arch="amd64">librdmacm-dev</baserpm>
      <baserpm install="yes" arch="amd64">librdmacm1</baserpm>
      <baserpm install="yes" arch="amd64">libxpmem-dev</baserpm>
      <baserpm install="yes" arch="amd64">libxpmem0</baserpm>
      <baserpm install="yes" arch="amd64">mft</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-ethtool</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-iproute2</baserpm>
      <baserpm install="yes" arch="all">mlnx-ofed-kernel-dkms</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-ofed-kernel-utils</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-tools</baserpm>
      <baserpm install="yes" arch="amd64">mpitests</baserpm>
      <baserpm install="yes" arch="amd64">ofed-scripts</baserpm>
      <baserpm install="yes" arch="all">openmpi</baserpm>
      <baserpm install="yes" arch="amd64">opensm</baserpm>
      <baserpm install="yes" arch="amd64">opensm-doc</baserpm>
      <baserpm install="yes" arch="amd64">perftest</baserpm>
      <baserpm install="yes" arch="amd64">rdma-core</baserpm>
      <baserpm install="yes" arch="amd64">rdmacm-utils</baserpm>
      <baserpm install="yes" arch="amd64">rshim</baserpm>
      <baserpm install="yes" arch="amd64">sharp</baserpm>
      <baserpm install="yes" arch="all">srp-dkms</baserpm>
      <baserpm install="yes" arch="amd64">srptools</baserpm>
      <baserpm install="yes" arch="amd64">ucx</baserpm>
      <baserpm install="yes" arch="all">xpmem</baserpm>
      <baserpm install="yes" arch="all">xpmem-dkms</baserpm>
      <baserpmstore>packagegroups/doca_ofed_2.9.3</baserpmstore>
      <cmrpmstore>packagegroups/doca_ofed_2.9.3</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="doca_ofed_3.1.0" install="no" media="yes">
      <package-no>ibsim-utils</package-no>
      <package-no>ibutils</package-no>
      <package-no>libumad2sim0</package-no>
      <package-no>libopensm9</package-no>
      <package-no>libibdm1</package-no>
      <package-no>libosmvendor5</package-no>
      <baserpm install="yes" arch="amd64">doca-ofed</baserpm>
      <baserpm install="yes" arch="amd64">dpcp</baserpm>
      <baserpm install="yes" arch="amd64">hcoll</baserpm>
      <baserpm install="yes" arch="amd64">ibacm</baserpm>
      <baserpm install="yes" arch="amd64">ibarr</baserpm>
      <baserpm install="yes" arch="amd64">ibdump</baserpm>
      <baserpm install="yes" arch="amd64">ibsim</baserpm>
      <baserpm install="yes" arch="all">ibsim-doc</baserpm>
      <baserpm install="yes" arch="amd64">ibutils2</baserpm>
      <baserpm install="yes" arch="amd64">ibverbs-providers</baserpm>
      <baserpm install="yes" arch="amd64">ibverbs-utils</baserpm>
      <baserpm install="yes" arch="amd64">infiniband-diags</baserpm>
      <baserpm install="yes" arch="all">iser-dkms</baserpm>
      <baserpm install="yes" arch="all">isert-dkms</baserpm>
      <baserpm install="yes" arch="all">kernel-mft-dkms</baserpm>
      <baserpm install="yes" arch="amd64">knem</baserpm>
      <baserpm install="yes" arch="all">knem-dkms</baserpm>
      <baserpm install="yes" arch="amd64">libibmad-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibmad5</baserpm>
      <baserpm install="yes" arch="amd64">libibnetdisc5</baserpm>
      <baserpm install="yes" arch="amd64">libibumad-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibumad3</baserpm>
      <baserpm install="yes" arch="amd64">libibverbs-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibverbs1</baserpm>
      <baserpm install="yes" arch="amd64">libopensm</baserpm>
      <baserpm install="yes" arch="amd64">libopensm-devel</baserpm>
      <baserpm install="yes" arch="amd64">librdmacm-dev</baserpm>
      <baserpm install="yes" arch="amd64">librdmacm1</baserpm>
      <baserpm install="yes" arch="amd64">libxpmem-dev</baserpm>
      <baserpm install="yes" arch="amd64">libxpmem0</baserpm>
      <baserpm install="yes" arch="amd64">mft</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-ethtool</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-iproute2</baserpm>
      <baserpm install="yes" arch="all">mlnx-ofed-kernel-dkms</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-ofed-kernel-utils</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-tools</baserpm>
      <baserpm install="yes" arch="amd64">mpitests</baserpm>
      <baserpm install="yes" arch="amd64">ofed-scripts</baserpm>
      <baserpm install="yes" arch="all">openmpi</baserpm>
      <baserpm install="yes" arch="amd64">opensm</baserpm>
      <baserpm install="yes" arch="amd64">opensm-doc</baserpm>
      <baserpm install="yes" arch="amd64">perftest</baserpm>
      <baserpm install="yes" arch="amd64">rdma-core</baserpm>
      <baserpm install="yes" arch="amd64">rdmacm-utils</baserpm>
      <baserpm install="yes" arch="amd64">rshim</baserpm>
      <baserpm install="yes" arch="amd64">sharp</baserpm>
      <baserpm install="yes" arch="all">srp-dkms</baserpm>
      <baserpm install="yes" arch="amd64">srptools</baserpm>
      <baserpm install="yes" arch="amd64">ucx</baserpm>
      <baserpm install="yes" arch="all">xpmem</baserpm>
      <baserpm install="yes" arch="all">xpmem-dkms</baserpm>
      <baserpmstore>packagegroups/doca_ofed_3.1.0</baserpmstore>
      <cmrpmstore>packagegroups/doca_ofed_3.1.0</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="doca_ofed_3.1.0-091513" install="no" media="yes">
      <package-no>ibsim-utils</package-no>
      <package-no>ibutils</package-no>
      <package-no>libumad2sim0</package-no>
      <package-no>libopensm9</package-no>
      <package-no>libibdm1</package-no>
      <package-no>libosmvendor5</package-no>
      <baserpmstore>packagegroups/doca_ofed_3.1.0-091513</baserpmstore>
      <cmrpmstore>packagegroups/doca_ofed_3.1.0-091513</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="doca_ofed_3.1.0-091548" install="no" media="yes">
      <package-no>ibsim-utils</package-no>
      <package-no>ibutils</package-no>
      <package-no>libumad2sim0</package-no>
      <package-no>libopensm9</package-no>
      <package-no>libibdm1</package-no>
      <package-no>libosmvendor5</package-no>
      <baserpm install="yes" arch="amd64">doca-ofed</baserpm>
      <baserpm install="yes" arch="amd64">dpcp</baserpm>
      <baserpm install="yes" arch="amd64">hcoll</baserpm>
      <baserpm install="yes" arch="amd64">ibacm</baserpm>
      <baserpm install="yes" arch="amd64">ibarr</baserpm>
      <baserpm install="yes" arch="amd64">ibdump</baserpm>
      <baserpm install="yes" arch="amd64">ibsim</baserpm>
      <baserpm install="yes" arch="all">ibsim-doc</baserpm>
      <baserpm install="yes" arch="amd64">ibutils2</baserpm>
      <baserpm install="yes" arch="amd64">ibverbs-providers</baserpm>
      <baserpm install="yes" arch="amd64">ibverbs-utils</baserpm>
      <baserpm install="yes" arch="amd64">infiniband-diags</baserpm>
      <baserpm install="yes" arch="all">iser-dkms</baserpm>
      <baserpm install="yes" arch="all">isert-dkms</baserpm>
      <baserpm install="yes" arch="all">kernel-mft-dkms</baserpm>
      <baserpm install="yes" arch="amd64">knem</baserpm>
      <baserpm install="yes" arch="all">knem-dkms</baserpm>
      <baserpm install="yes" arch="amd64">libibmad-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibmad5</baserpm>
      <baserpm install="yes" arch="amd64">libibnetdisc5</baserpm>
      <baserpm install="yes" arch="amd64">libibumad-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibumad3</baserpm>
      <baserpm install="yes" arch="amd64">libibverbs-dev</baserpm>
      <baserpm install="yes" arch="amd64">libibverbs1</baserpm>
      <baserpm install="yes" arch="amd64">libopensm</baserpm>
      <baserpm install="yes" arch="amd64">libopensm-devel</baserpm>
      <baserpm install="yes" arch="amd64">librdmacm-dev</baserpm>
      <baserpm install="yes" arch="amd64">librdmacm1</baserpm>
      <baserpm install="yes" arch="amd64">libxpmem-dev</baserpm>
      <baserpm install="yes" arch="amd64">libxpmem0</baserpm>
      <baserpm install="yes" arch="amd64">mft</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-ethtool</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-iproute2</baserpm>
      <baserpm install="yes" arch="all">mlnx-ofed-kernel-dkms</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-ofed-kernel-utils</baserpm>
      <baserpm install="yes" arch="amd64">mlnx-tools</baserpm>
      <baserpm install="yes" arch="amd64">mpitests</baserpm>
      <baserpm install="yes" arch="amd64">ofed-scripts</baserpm>
      <baserpm install="yes" arch="all">openmpi</baserpm>
      <baserpm install="yes" arch="amd64">opensm</baserpm>
      <baserpm install="yes" arch="amd64">opensm-doc</baserpm>
      <baserpm install="yes" arch="amd64">perftest</baserpm>
      <baserpm install="yes" arch="amd64">rdma-core</baserpm>
      <baserpm install="yes" arch="amd64">rdmacm-utils</baserpm>
      <baserpm install="yes" arch="amd64">rshim</baserpm>
      <baserpm install="yes" arch="amd64">sharp</baserpm>
      <baserpm install="yes" arch="all">srp-dkms</baserpm>
      <baserpm install="yes" arch="amd64">srptools</baserpm>
      <baserpm install="yes" arch="amd64">ucx</baserpm>
      <baserpm install="yes" arch="all">xpmem</baserpm>
      <baserpm install="yes" arch="all">xpmem-dkms</baserpm>
      <baserpmstore>packagegroups/doca_ofed_3.1.0-091548</baserpmstore>
      <cmrpmstore>packagegroups/doca_ofed_3.1.0-091548</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="hpc" install="yes" media="yes">
      <cmrpm install="yes" arch="amd64">openpbs23.06-client</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05-slurmd</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05-slurmctld</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05-slurmdbd</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05-contribs</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05-perlapi</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05-devel</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm25.05-prs</cmrpm>
      <cmrpm install="yes" arch="amd64">enroot</cmrpm>
      <cmrpm install="yes" arch="amd64">enroot+caps</cmrpm>
      <cmrpm install="yes" arch="all">cm-uge-client</cmrpm>
      <cmrpm install="yes" arch="all">cm-lsf-client</cmrpm>
      <cmrpm install="yes" arch="amd64">munge</cmrpm>
      <cmrpm install="yes" arch="amd64">libmunge2</cmrpm>
      <baserpmstore>packagegroups/hpc</baserpmstore>
      <cmrpmstore>packagegroups/hpc</cmrpmstore>
    </ExtraPackageGroup>
    <ExtraPackageGroup name="bcm-extra" install="no" media="yes">
      <cmrpm install="yes" arch="amd64">slurm24.11</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm24.11-slurmd</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm24.11-slurmctld</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm24.11-slurmdbd</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm24.11-contribs</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm24.11-perlapi</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm24.11-devel</cmrpm>
      <cmrpm install="yes" arch="amd64">slurm24.11-prs</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-containerd</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-harbor</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-docker</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-docker-compose</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-docker-registry</cmrpm>
      <cmrpm install="yes" arch="amd64">cm-etcd</cmrpm>
      <baserpmstore>packagegroups/bcm-extra</baserpmstore>
      <cmrpmstore>packagegroups/bcm-extra</cmrpmstore>
    </ExtraPackageGroup>
    <basetar>UBUNTU2404.tar.gz</basetar>
  </SlaveImage>
  <RackLayout>
    <Rack index="0">
      <MasterNode>
        <hostname>{{ hostname }}</hostname>
        <mac>MYMAC</mac>
        <role>master</role>
        <role>storage</role>
        <role>login</role>
        <role>backup</role>
        <role>monitoring</role>
        <role>provisioning</role>
        <role>boot</role>
{% for iface in interfaces %}
        <interface>
          <iface>{{ iface.name }}</iface>
          <network>{{ iface.network }}</network>
          <ip>{{ iface.ip }}</ip>
{% if iface.provisioning | default(false) %}
          <provisioning/>
{% endif %}
        </interface>
{% endfor %}
      </MasterNode>
      <SlaveNode>
        <hostname>node001</hostname>
        <interface>
          <iface>BOOTIF</iface>
          <ip>{{ slave_ip | default('10.141.0.1') }}</ip>
          <network>internalnet</network>
          <provisioning/>
        </interface>
        <category>default</category>
      </SlaveNode>
    </Rack>
  </RackLayout>
  <workloadname>pbspro-ce</workloadname>
  <workloadslots>8</workloadslots>
  <workloadmastercomp>no</workloadmastercomp>
  <hardwarevendor>other</hardwarevendor>
  <keyboardlayout>us</keyboardlayout>
  <consolemaster>text</consolemaster>
  <consoleslave>text</consoleslave>
  <globalnetworksetup>nwsetup1</globalnetworksetup>
  <ibnodebooting>no</ibnodebooting>
  <FSPart>
    <path>/cm/shared</path>
    <type>cm-shared</type>
    <autoDirtyDelay>3600</autoDirtyDelay>
  </FSPart>
  <FSPart>
    <path>/cm/node-installer</path>
    <type>node-installer</type>
    <autoDirtyDelay>3600</autoDirtyDelay>
  </FSPart>
  <stablerelease>11.31.1</stablerelease>
  <BurnConfig>
    <default/>
    <name>default-destructive</name>
    <description>Standard destructive burn test. Beware, wipes the disks!</description>
    <configuration><![CDATA[
    <burnconfig>

      <!-- The framework can send e-mail on failure. This is an optional tag. -->
      <!-- Multiple addresses can be specified. -->
      <mail>
        <address>root@master</address>
        <!-- <address>some@other.address</address> -->
      </mail>

      <!-- Tests executed from the installer -->
      <pre-install>

        <!-- Gather hardware information -->
        <phase name="01-hwinfo">
          <test name="hwinfo"/>
          <test name="sleep" args="10"/>
        </phase>

        <!-- Measure write speed of harddrive with CPUs idle -->
        <phase name="02-disks">
          <test name="disktest" args="30"/>
          <test name="mce_check" endless="1"/>
          <test name="kmon" endless="1"/>
        </phase>

        <!-- Measure write speed of harddrive while stressing CPUs -->
        <phase name="03-disks-cpu">
          <test name="disktest"/>
          <test name="stresscpu" args="60"/>
          <test name="mce_check" endless="1"/>
        <test name="kmon" endless="1"/>
        </phase>

        <!-- Check for bad blocks while running memory-test -->
        <phase name="04-bblocks-mem">
          <test name="memtester" args="1"/>
          <test name="bblocks"/>
          <test name="mce_check" endless="1"/>
          <test name="kmon" endless="1"/>
        </phase>

        <!-- Perform APC reset test -->
        <phase name="05-apc">
          <test name="powertest" args="25"/>
        </phase>

      </pre-install>

      <!-- Tests executed after a full installation -->
      <post-install>

        <!-- Check for bad blocks while running Linpack on all CPUs -->
        <phase name="06-hpl">
          <!-- hpl can have 3 args, first is desired runtime in hours  -->
          <!-- second is the percentage of mem to use, third is a marging in MB -->
          <test name="hpl"/>
          <test name="mce_check" endless="1"/>
          <test name="kmon" endless="1"/>
        </phase>

        <!-- Compile the Linux kernel a couple of times -->
        <phase name="07-compile">
          <test name="compile" args="6"/>
          <test name="mce_check" endless="1"/>
          <test name="kmon" endless="1"/>
        </phase>

        <!-- Run mprime torture test for an hour -->
        <phase name="08-mprime">
          <test name="mprime"/>
          <test name="mce_check" endless="1"/>
          <test name="kmon" endless="1"/>
        </phase>

      </post-install>

    </burnconfig>
]]></configuration>
  </BurnConfig>
  <BurnConfig>
    <name>long-hpl</name>
    <description>Run HPL test for a long time.</description>
    <configuration><![CDATA[
    <burnconfig>

      <!-- The framework can send e-mail on failure. This is an optional tag. -->
      <!-- Multiple addresses can be specified. -->
      <mail>
        <address>root@master</address>
        <!-- <address>some@other.address</address> -->
      </mail>
      <!-- Tests executed from the installer -->
      <pre-install>
        <!-- Pre-installer is empty for this one -->
      </pre-install>
      <!-- Tests executed after a full installation -->
      <post-install>
        <!-- Check for bad blocks while running Linpack on all CPUs -->
        <phase name="01-hpl">
          <!-- hpl can have 3 args, first is desired runtime in hours  -->
          <!-- second is the percentage of mem to use, third is a marging in MB -->
          <test name="hpl" args="72"/>
          <test name="mce_check" endless="1"/>
        </phase>
      </post-install>

    </burnconfig>
]]></configuration>
  </BurnConfig>
  <BurnConfig>
    <name>gpu-burn</name>
    <description>Run burn tests on NVIDIA GPUs</description>
    <configuration><![CDATA[
    <burnconfig>

      <!-- The framework can send e-mail on failure. This is an optional tag. -->
      <!-- Multiple addresses can be specified. -->
      <mail>
        <address>root@master</address>
        <!-- <address>some@other.address</address> -->
      </mail>
      <pre-install>
      </pre-install>

      <post-install>
        <phase name="01-gpu-burn">
          <!-- Argument is test intensity from 1 to 4 -->
          <test name="gpu_burn" args="-r 4"/>
        </phase>
      </post-install>

    </burnconfig>
]]></configuration>
  </BurnConfig>
  <NodeInstallerImage>
    <name>node-installer</name>
    <baserpmstore>dist/ubuntu/2404</baserpmstore>
    <cmrpmstore>11.31.1/ubuntu/2404</cmrpmstore>
    <baserpm install="yes" arch="amd64">libwind0t64-heimdal</baserpm>
    <baserpm install="yes" arch="amd64">postfix</baserpm>
    <baserpm install="yes" arch="amd64">openssh-client</baserpm>
    <baserpm install="yes" arch="amd64">liburcu8t64</baserpm>
    <baserpm install="yes" arch="amd64">python3-ntp</baserpm>
    <baserpm install="yes" arch="amd64">procps</baserpm>
    <baserpm install="yes" arch="amd64">libtss2-tcti-spi-helper0t64</baserpm>
    <baserpm install="yes" arch="amd64">libncurses6</baserpm>
    <baserpm install="yes" arch="amd64">libtss2-tcti-cmd0t64</baserpm>
    <baserpm install="yes" arch="amd64">openssl</baserpm>
    <baserpm install="yes" arch="amd64">grub-efi-amd64-bin</baserpm>
    <baserpm install="yes" arch="amd64">libbinutils</baserpm>
    <baserpm install="yes" arch="amd64">libstdc++6</baserpm>
    <baserpm install="yes" arch="amd64">libsocket6-perl</baserpm>
    <baserpm install="yes" arch="amd64">dmraid</baserpm>
    <baserpm install="yes" arch="amd64">grub-efi-amd64-signed</baserpm>
    <baserpm install="yes" arch="amd64">dmeventd</baserpm>
    <baserpm install="yes" arch="amd64">efibootmgr</baserpm>
    <baserpm install="yes" arch="amd64">info</baserpm>
    <baserpm install="yes" arch="amd64">libsframe1</baserpm>
    <baserpm install="yes" arch="amd64">libfuse2t64</baserpm>
    <baserpm install="yes" arch="amd64">libboost-random1.83.0</baserpm>
    <baserpm install="yes" arch="amd64">libsensors5</baserpm>
    <baserpm install="yes" arch="amd64">libasn1-8t64-heimdal</baserpm>
    <baserpm install="yes" arch="amd64">thin-provisioning-tools</baserpm>
    <baserpm install="yes" arch="amd64">iputils-arping</baserpm>
    <baserpm install="yes" arch="amd64">strace</baserpm>
    <baserpm install="yes" arch="amd64">zerofree</baserpm>
    <baserpm install="yes" arch="amd64">libtss2-mu-4.0.1-0t64</baserpm>
    <baserpm install="yes" arch="amd64">btrfs-progs</baserpm>
    <baserpm install="yes" arch="amd64">libnfnetlink0</baserpm>
    <baserpm install="yes" arch="amd64">grub-common</baserpm>
    <baserpm install="yes" arch="amd64">libsigsegv2</baserpm>
    <baserpm install="yes" arch="amd64">libacl1</baserpm>
    <baserpm install="yes" arch="amd64">logrotate</baserpm>
    <baserpm install="yes" arch="amd64">libnftables1</baserpm>
    <baserpm install="yes" arch="amd64">ntpsec</baserpm>
    <baserpm install="yes" arch="amd64">libboost-thread1.83.0</baserpm>
    <baserpm install="yes" arch="amd64">libboost-system1.83.0</baserpm>
    <baserpm install="yes" arch="amd64">liblvm2cmd2.03</baserpm>
    <baserpm install="yes" arch="amd64">libboost-iostreams1.83.0</baserpm>
    <baserpm install="yes" arch="amd64">wget</baserpm>
    <baserpm install="yes" arch="amd64">openssh-sftp-server</baserpm>
    <baserpm install="yes" arch="amd64">libkrb5-26t64-heimdal</baserpm>
    <baserpm install="yes" arch="amd64">libdmraid1.0.0.rc16</baserpm>
    <baserpm install="yes" arch="amd64">mdadm</baserpm>
    <baserpm install="yes" arch="amd64">libhx509-5t64-heimdal</baserpm>
    <baserpm install="yes" arch="amd64">lua-lpeg</baserpm>
    <baserpm install="yes" arch="amd64">rng-tools-debian</baserpm>
    <baserpm install="yes" arch="amd64">libsnmp40t64</baserpm>
    <baserpm install="yes" arch="amd64">libmagic-mgc</baserpm>
    <baserpm install="yes" arch="amd64">dosfstools</baserpm>
    <baserpm install="yes" arch="amd64">grub-efi-amd64</baserpm>
    <baserpm install="yes" arch="amd64">tftp-hpa</baserpm>
    <baserpm install="yes" arch="amd64">libgpm2</baserpm>
    <baserpm install="yes" arch="amd64">pciutils</baserpm>
    <baserpm install="yes" arch="amd64">libefivar1t64</baserpm>
    <baserpm install="yes" arch="amd64">xz-utils</baserpm>
    <baserpm install="yes" arch="amd64">ethtool</baserpm>
    <baserpm install="yes" arch="amd64">libcryptsetup12</baserpm>
    <baserpm install="yes" arch="amd64">nfs-common</baserpm>
    <baserpm install="yes" arch="amd64">libcommon-sense-perl</baserpm>
    <baserpm install="yes" arch="amd64">libip4tc2</baserpm>
    <baserpm install="yes" arch="amd64">librdmacm1t64</baserpm>
    <baserpm install="yes" arch="amd64">less</baserpm>
    <baserpm install="yes" arch="amd64">libgssapi-krb5-2</baserpm>
    <baserpm install="yes" arch="amd64">dmsetup</baserpm>
    <baserpm install="yes" arch="amd64">libtirpc3t64</baserpm>
    <baserpm install="yes" arch="amd64">libtss2-sys1t64</baserpm>
    <baserpm install="yes" arch="amd64">snmp</baserpm>
    <baserpm install="yes" arch="amd64">liblmdb0</baserpm>
    <baserpm install="yes" arch="amd64">libk5crypto3</baserpm>
    <baserpm install="yes" arch="amd64">libdevmapper1.02.1</baserpm>
    <baserpm install="yes" arch="amd64">libcrack2</baserpm>
    <baserpm install="yes" arch="amd64">bind9-utils</baserpm>
    <baserpm install="yes" arch="amd64">libevent-pthreads-2.1-7t64</baserpm>
    <baserpm install="yes" arch="amd64">libkeyutils1</baserpm>
    <baserpm install="yes" arch="amd64">librados2</baserpm>
    <baserpm install="yes" arch="amd64">curl</baserpm>
    <baserpm install="yes" arch="amd64">libjq1</baserpm>
    <baserpm install="yes" arch="amd64">libroken19t64-heimdal</baserpm>
    <baserpm install="yes" arch="amd64">libnsl2</baserpm>
    <baserpm install="yes" arch="amd64">libnl-3-200</baserpm>
    <baserpm install="yes" arch="amd64">lsscsi</baserpm>
    <baserpm install="yes" arch="amd64">libctf0</baserpm>
    <baserpm install="yes" arch="amd64">libgomp1</baserpm>
    <baserpm install="yes" arch="amd64">secureboot-db</baserpm>
    <baserpm install="yes" arch="amd64">net-tools</baserpm>
    <baserpm install="yes" arch="amd64">libjson-xs-perl</baserpm>
    <baserpm install="yes" arch="amd64">libpsl5t64</baserpm>
    <baserpm install="yes" arch="amd64">nvme-cli</baserpm>
    <baserpm install="yes" arch="amd64">libgcc-s1</baserpm>
    <baserpm install="yes" arch="amd64">libcurl4t64</baserpm>
    <baserpm install="yes" arch="amd64">gettext</baserpm>
    <baserpm install="yes" arch="amd64">libip6tc2</baserpm>
    <baserpm install="yes" arch="amd64">libfreetype6</baserpm>
    <baserpm install="yes" arch="amd64">gettext-base</baserpm>
    <baserpm install="yes" arch="amd64">libefiboot1t64</baserpm>
    <baserpm install="yes" arch="amd64">libheimbase1t64-heimdal</baserpm>
    <baserpm install="yes" arch="amd64">libpci3</baserpm>
    <baserpm install="yes" arch="amd64">libyaml-0-2</baserpm>
    <baserpm install="yes" arch="amd64">nmap</baserpm>
    <baserpm install="yes" arch="amd64">libjansson4</baserpm>
    <baserpm install="yes" arch="amd64">python3.12</baserpm>
    <baserpm install="yes" arch="amd64">libxtables12</baserpm>
    <baserpm install="yes" arch="amd64">cracklib-runtime</baserpm>
    <baserpm install="yes" arch="amd64">libldap2</baserpm>
    <baserpm install="yes" arch="amd64">libsasl2-modules</baserpm>
    <baserpm install="yes" arch="amd64">libsasl2-2</baserpm>
    <baserpm install="yes" arch="amd64">libtss2-fapi1t64</baserpm>
    <baserpm install="yes" arch="amd64">bc</baserpm>
    <baserpm install="yes" arch="amd64">perl-base</baserpm>
    <baserpm install="yes" arch="amd64">liblinear4</baserpm>
    <baserpm install="yes" arch="amd64">xinetd</baserpm>
    <baserpm install="yes" arch="amd64">libevent-2.1-7t64</baserpm>
    <baserpm install="yes" arch="amd64">sg3-utils</baserpm>
    <baserpm install="yes" arch="amd64">libssh2-1t64</baserpm>
    <baserpm install="yes" arch="amd64">zip</baserpm>
    <baserpm install="yes" arch="amd64">linux-firmware</baserpm>
    <baserpm install="yes" arch="amd64">libnss3</baserpm>
    <baserpm install="yes" arch="amd64">libevent-core-2.1-7t64</baserpm>
    <baserpm install="yes" arch="amd64">bind9-dnsutils</baserpm>
    <baserpm install="yes" arch="amd64">libsgutils2-1.46-2</baserpm>
    <baserpm install="yes" arch="amd64">gawk</baserpm>
    <baserpm install="yes" arch="amd64">sbsigntool</baserpm>
    <baserpm install="yes" arch="amd64">libproc2-0</baserpm>
    <baserpm install="yes" arch="amd64">libibverbs1</baserpm>
    <baserpm install="yes" arch="amd64">jq</baserpm>
    <baserpm install="yes" arch="amd64">libestr0</baserpm>
    <baserpm install="yes" arch="amd64">dc</baserpm>
    <baserpm install="yes" arch="amd64">lsof</baserpm>
    <baserpm install="yes" arch="amd64">libopeniscsiusr</baserpm>
    <baserpm install="yes" arch="amd64">libcurl3t64-gnutls</baserpm>
    <baserpm install="yes" arch="amd64">cryptsetup</baserpm>
    <baserpm install="yes" arch="amd64">libmaxminddb0</baserpm>
    <baserpm install="yes" arch="amd64">perl-openssl-defaults</baserpm>
    <baserpm install="yes" arch="amd64">libgprofng0</baserpm>
    <baserpm install="yes" arch="amd64">keyutils</baserpm>
    <baserpm install="yes" arch="amd64">libhtml-parser-perl</baserpm>
    <baserpm install="yes" arch="amd64">libpcap0.8t64</baserpm>
    <baserpm install="yes" arch="amd64">libnvme1t64</baserpm>
    <baserpm install="yes" arch="amd64">libaio1t64</baserpm>
    <baserpm install="yes" arch="amd64">grub2-common</baserpm>
    <baserpm install="yes" arch="amd64">ntpsec-ntpdig</baserpm>
    <baserpm install="yes" arch="amd64">file</baserpm>
    <baserpm install="yes" arch="amd64">libclone-perl</baserpm>
    <baserpm install="yes" arch="amd64">libuv1t64</baserpm>
    <baserpm install="yes" arch="amd64">ibverbs-providers</baserpm>
    <baserpm install="yes" arch="amd64">binutils-common</baserpm>
    <baserpm install="yes" arch="amd64">libpython3.12-minimal</baserpm>
    <baserpm install="yes" arch="amd64">openssh-server</baserpm>
    <baserpm install="yes" arch="amd64">gcc-14-base</baserpm>
    <baserpm install="yes" arch="amd64">psmisc</baserpm>
    <baserpm install="yes" arch="amd64">libblas3</baserpm>
    <baserpm install="yes" arch="amd64">python3.12-minimal</baserpm>
    <baserpm install="yes" arch="amd64">libnetfilter-conntrack3</baserpm>
    <baserpm install="yes" arch="amd64">xsltproc</baserpm>
    <baserpm install="yes" arch="amd64">libreadline8t64</baserpm>
    <baserpm install="yes" arch="amd64">rsyslog</baserpm>
    <baserpm install="yes" arch="amd64">lldpd</baserpm>
    <baserpm install="yes" arch="amd64">libnl-route-3-200</baserpm>
    <baserpm install="yes" arch="amd64">bridge-utils</baserpm>
    <baserpm install="yes" arch="amd64">libisns0t64</baserpm>
    <baserpm install="yes" arch="amd64">liblua5.4-0</baserpm>
    <baserpm install="yes" arch="amd64">liblua5.3-0</baserpm>
    <baserpm install="yes" arch="amd64">libtss2-esys-3.0.2-0t64</baserpm>
    <baserpm install="yes" arch="amd64">lvm2</baserpm>
    <baserpm install="yes" arch="amd64">libsasl2-modules-db</baserpm>
    <baserpm install="yes" arch="amd64">open-iscsi</baserpm>
    <baserpm install="yes" arch="amd64">msr-tools</baserpm>
    <baserpm install="yes" arch="amd64">libonig5</baserpm>
    <baserpm install="yes" arch="amd64">tpm2-tools</baserpm>
    <baserpm install="yes" arch="amd64">libpython3.12-stdlib</baserpm>
    <baserpm install="yes" arch="amd64">ltrace</baserpm>
    <baserpm install="yes" arch="amd64">kpartx</baserpm>
    <baserpm install="yes" arch="amd64">libtss2-rc0t64</baserpm>
    <baserpm install="yes" arch="amd64">grub-pc-bin</baserpm>
    <baserpm install="yes" arch="amd64">libctf-nobfd0</baserpm>
    <baserpm install="yes" arch="amd64">libdevmapper-event1.02.1</baserpm>
    <baserpm install="yes" arch="amd64">bind9-libs</baserpm>
    <baserpm install="yes" arch="amd64">os-prober</baserpm>
    <baserpm install="yes" arch="amd64">jfsutils</baserpm>
    <baserpm install="yes" arch="amd64">tcpdump</baserpm>
    <baserpm install="yes" arch="amd64">dmidecode</baserpm>
    <baserpm install="yes" arch="amd64">uuid-runtime</baserpm>
    <baserpm install="yes" arch="amd64">libfastjson4</baserpm>
    <baserpm install="yes" arch="amd64">perl</baserpm>
    <baserpm install="yes" arch="amd64">libtss2-tcti-swtpm0t64</baserpm>
    <baserpm install="yes" arch="amd64">ebtables</baserpm>
    <baserpm install="yes" arch="amd64">libperl5.38t64</baserpm>
    <baserpm install="yes" arch="amd64">libnfsidmap1</baserpm>
    <baserpm install="yes" arch="amd64">multipath-tools</baserpm>
    <baserpm install="yes" arch="amd64">binutils-x86-64-linux-gnu</baserpm>
    <baserpm install="yes" arch="amd64">libssl3t64</baserpm>
    <baserpm install="yes" arch="amd64">libnspr4</baserpm>
    <baserpm install="yes" arch="amd64">util-linux-extra</baserpm>
    <baserpm install="yes" arch="amd64">binutils</baserpm>
    <baserpm install="yes" arch="amd64">libxxhash0</baserpm>
    <baserpm install="yes" arch="amd64">libopts25</baserpm>
    <baserpm install="yes" arch="amd64">libmpfr6</baserpm>
    <baserpm install="yes" arch="amd64">libpng16-16t64</baserpm>
    <baserpm install="yes" arch="amd64">iptables</baserpm>
    <baserpm install="yes" arch="amd64">xxhash</baserpm>
    <baserpm install="yes" arch="amd64">libnet-ssleay-perl</baserpm>
    <baserpm install="yes" arch="amd64">selinux-utils</baserpm>
    <baserpm install="yes" arch="amd64">rsync</baserpm>
    <baserpm install="yes" arch="amd64">nftables</baserpm>
    <baserpm install="yes" arch="amd64">libedit2</baserpm>
    <baserpm install="yes" arch="amd64">libwrap0</baserpm>
    <baserpm install="yes" arch="amd64">libxml-libxml-perl</baserpm>
    <baserpm install="yes" arch="amd64">xfsprogs</baserpm>
    <baserpm install="yes" arch="amd64">util-linux</baserpm>
    <baserpm install="yes" arch="amd64">libtss2-tcti-device0t64</baserpm>
    <baserpm install="yes" arch="amd64">groff-base</baserpm>
    <baserpm install="yes" arch="amd64">acl</baserpm>
    <baserpm install="yes" arch="amd64">bind9-host</baserpm>
    <baserpm install="yes" arch="amd64">libtss2-tcti-mssim0t64</baserpm>
    <baserpm install="yes" arch="amd64">libkrb5-3</baserpm>
    <baserpm install="yes" arch="amd64">ntpsec-ntpdate</baserpm>
    <baserpm install="yes" arch="amd64">libhcrypto5t64-heimdal</baserpm>
    <baserpm install="yes" arch="amd64">libkrb5support0</baserpm>
    <baserpm install="yes" arch="amd64">libnftnl11</baserpm>
    <baserpm install="yes" arch="amd64">libtss2-tctildr0t64</baserpm>
    <baserpm install="yes" arch="amd64">libtss2-tcti-libtpms0t64</baserpm>
    <baserpm install="yes" arch="amd64">memtester</baserpm>
    <baserpm install="yes" arch="amd64">libmagic1t64</baserpm>
    <baserpm install="yes" arch="amd64">kmod</baserpm>
    <baserpm install="yes" arch="amd64">libpython3.12t64</baserpm>
    <baserpm install="yes" arch="amd64">libxml-parser-perl</baserpm>
    <baserpm install="yes" arch="amd64">policycoreutils</baserpm>
    <baserpm install="yes" arch="amd64">install-info</baserpm>
    <baserpm install="yes" arch="amd64">iputils-tracepath</baserpm>
    <baserpm install="yes" arch="amd64">cryptsetup-bin</baserpm>
    <baserpm install="yes" arch="amd64">make</baserpm>
    <baserpm install="yes" arch="amd64">libxslt1.1</baserpm>
    <baserpm install="yes" arch="amd64">unzip</baserpm>
    <baserpm install="yes" arch="amd64">rpcbind</baserpm>
    <baserpm install="yes" arch="all">libjson-perl</baserpm>
    <baserpm install="yes" arch="all">krb5-locales</baserpm>
    <baserpm install="yes" arch="all">ssh-import-id</baserpm>
    <baserpm install="yes" arch="all">libhtml-form-perl</baserpm>
    <baserpm install="yes" arch="all">libio-socket-ssl-perl</baserpm>
    <baserpm install="yes" arch="all">perl-modules-5.38</baserpm>
    <baserpm install="yes" arch="all">liblwp-protocol-https-perl</baserpm>
    <baserpm install="yes" arch="all">libsnmp-base</baserpm>
    <baserpm install="yes" arch="all">libhttp-message-perl</baserpm>
    <baserpm install="yes" arch="all">python3-ply</baserpm>
    <baserpm install="yes" arch="all">libxml-namespacesupport-perl</baserpm>
    <baserpm install="yes" arch="all">libauthen-sasl-perl</baserpm>
    <baserpm install="yes" arch="all">liburi-perl</baserpm>
    <baserpm install="yes" arch="all">sg3-utils-udev</baserpm>
    <baserpm install="yes" arch="all">wamerican</baserpm>
    <baserpm install="yes" arch="all">libfile-listing-perl</baserpm>
    <baserpm install="yes" arch="all">libhtml-tree-perl</baserpm>
    <baserpm install="yes" arch="all">libfile-copy-recursive-perl</baserpm>
    <baserpm install="yes" arch="all">libtry-tiny-perl</baserpm>
    <baserpm install="yes" arch="all">libtypes-serialiser-perl</baserpm>
    <baserpm install="yes" arch="all">cryptsetup-initramfs</baserpm>
    <baserpm install="yes" arch="all">libio-html-perl</baserpm>
    <baserpm install="yes" arch="all">ssl-cert</baserpm>
    <baserpm install="yes" arch="all">ntpdate</baserpm>
    <baserpm install="yes" arch="all">libtirpc-common</baserpm>
    <baserpm install="yes" arch="all">liblwp-mediatypes-perl</baserpm>
    <baserpm install="yes" arch="all">libhttp-daemon-perl</baserpm>
    <baserpm install="yes" arch="all">libhttp-date-perl</baserpm>
    <baserpm install="yes" arch="all">firmware-sof-signed</baserpm>
    <baserpm install="yes" arch="all">libxml-sax-expat-perl</baserpm>
    <baserpm install="yes" arch="all">libfont-afm-perl</baserpm>
    <baserpm install="yes" arch="all">kpartx-boot</baserpm>
    <baserpm install="yes" arch="all">tpm-udev</baserpm>
    <baserpm install="yes" arch="all">libtimedate-perl</baserpm>
    <baserpm install="yes" arch="all">nmap-common</baserpm>
    <baserpm install="yes" arch="all">libsensors-config</baserpm>
    <baserpm install="yes" arch="all">update-inetd</baserpm>
    <baserpm install="yes" arch="all">ca-certificates</baserpm>
    <baserpm install="yes" arch="all">libwww-perl</baserpm>
    <baserpm install="yes" arch="all">ntp</baserpm>
    <baserpm install="yes" arch="all">dnsutils</baserpm>
    <baserpm install="yes" arch="all">libxml-sax-base-perl</baserpm>
    <baserpm install="yes" arch="all">libwww-robotrules-perl</baserpm>
    <baserpm install="yes" arch="all">sntp</baserpm>
    <baserpm install="yes" arch="all">python3-prettytable</baserpm>
    <baserpm install="yes" arch="all">libhttp-negotiate-perl</baserpm>
    <baserpm install="yes" arch="all">javascript-common</baserpm>
    <baserpm install="yes" arch="all">libstring-shellquote-perl</baserpm>
    <baserpm install="yes" arch="all">libldap-common</baserpm>
    <baserpm install="yes" arch="all">ncurses-term</baserpm>
    <baserpm install="yes" arch="all">libmailtools-perl</baserpm>
    <baserpm install="yes" arch="all">libdata-dump-perl</baserpm>
    <baserpm install="yes" arch="all">libhtml-tagset-perl</baserpm>
    <baserpm install="yes" arch="all">libhttp-cookies-perl</baserpm>
    <baserpm install="yes" arch="all">vlan</baserpm>
    <baserpm install="yes" arch="all">libxml-sax-perl</baserpm>
    <baserpm install="yes" arch="all">libnet-smtp-ssl-perl</baserpm>
    <baserpm install="yes" arch="all">libhtml-format-perl</baserpm>
    <baserpm install="yes" arch="all">libencode-locale-perl</baserpm>
    <baserpm install="yes" arch="all">libnet-http-perl</baserpm>
    <cmrpm install="yes" arch="all">cm-config-cm</cmrpm>
    <cmrpm install="yes" arch="all">cm-config-apt</cmrpm>
    <cmrpm install="yes" arch="amd64">cmdaemon-remotecm</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-gmp</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-sdparm</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-sedutil</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-logmon</cmrpm>
    <cmrpm install="yes" arch="amd64">cuda-dcgm-libs</cmrpm>
    <cmrpm install="yes" arch="amd64">cmdaemon-node-installer</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-ipmitool</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-libprometheus</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-openvpn</cmrpm>
    <cmrpm install="yes" arch="amd64">gdb-recent</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-gcc</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-python312</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-rsync</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-config-os-arch</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-curl</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-confuse</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-mpfr</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-openssl</cmrpm>
    <cmrpm install="yes" arch="amd64">net-snmp-recent</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-mpc</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-mysql++</cmrpm>
    <cmrpm install="yes" arch="amd64">node-installer</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-python3</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-boost</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-parted</cmrpm>
    <cmrpm install="yes" arch="amd64">cm-mariadb-libs</cmrpm>
    <ExtraPackageGroup name="default" install="yes" media="yes">
      <baserpm install="yes" arch="amd64">nv-disk-encrypt</baserpm>
      <baserpm install="yes" arch="all">nv-common-apis</baserpm>
      <baserpmstore>packagegroups/default</baserpmstore>
      <cmrpmstore>packagegroups/default</cmrpmstore>
    </ExtraPackageGroup>
  </NodeInstallerImage>
  <Monitoring>
    <MonitoringAction>
      <name>killprocess</name>
      <childType>MonitoringScriptAction</childType>
      <script><![CDATA[/cm/local/apps/cmd/scripts/actions/killprocess.pl]]></script>
      <description>Action which kills processes of pids found in STDIN</description>
      <timeout>5</timeout>
      <runOn>NODE</runOn>
    </MonitoringAction>
    <MonitoringAction>
      <name>testaction</name>
      <childType>MonitoringScriptAction</childType>
      <script><![CDATA[/cm/local/apps/cmd/scripts/actions/testaction]]></script>
      <description>action to test, it generates output in a file for e.g. debugging</description>
      <timeout>5</timeout>
      <runOn>NODE</runOn>
    </MonitoringAction>
    <MonitoringAction>
      <name>remount</name>
      <childType>MonitoringScriptAction</childType>
      <script><![CDATA[/cm/local/apps/cmd/scripts/actions/remount]]></script>
      <description>action which tries to fix broken fs mounts, e.g. when device is not mounted while it is defined in cmd</description>
      <timeout>60</timeout>
      <runOn>NODE</runOn>
    </MonitoringAction>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>wlm-drain-status</name>
      <description>Samples drain status of all WLM</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_wlm_drain_status.py]]></script>
      <maxSamples>4096</maxSamples>
      <startupDelay>60</startupDelay>
      <interval>120</interval>
      <timeout>30</timeout>
      <consolidator>none</consolidator>
      <disabled>yes</disabled>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Active head node</name>
        <resources>Active</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>sample-nv-metrics</name>
      <description>Samples metrics using nv show</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_nv_metrics.py]]></script>
      <startupDelay>60</startupDelay>
      <interval>120</interval>
      <timeout>30</timeout>
      <MonitoringExecutionFilter>
        <childType>MonitoringTypeExecutionFilter</childType>
        <name>Switches</name>
        <types>Switch</types>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>sample-nv-sdn-metrics</name>
      <description>Samples metrics using nv show</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_nv_sdn_partitions.py]]></script>
      <startupDelay>60</startupDelay>
      <interval>120</interval>
      <timeout>30</timeout>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>NVLink switches</name>
        <resources>NVLINK</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>sample-hwmon-metrics</name>
      <description>Samples power metrics /sys/class/hwmon</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_hwmon_metrics.py]]></script>
      <startupDelay>60</startupDelay>
      <interval>120</interval>
      <timeout>30</timeout>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>NVLink switches</name>
        <resources>NVLINK</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>netq</name>
      <description>Samples metrics from NetQ managed devices</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_netq]]></script>
      <maxSamples>4096</maxSamples>
      <maxMeasurables>4096</maxMeasurables>
      <startupDelay>60</startupDelay>
      <interval>120</interval>
      <timeout>30</timeout>
      <consolidator>default</consolidator>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Active head node with NetQ server</name>
        <resources>Active</resources>
        <resources>NetQ</resources>
        <op>AND</op>
      </MonitoringExecutionFilter>
      <extra_values><![CDATA[
{
  "AdditionalOperation": ["--entities"]
}
]]></extra_values>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>nmxm</name>
      <description>Samples metrics from NMX-M</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_nmxm]]></script>
      <maxSamples>4096</maxSamples>
      <startupDelay>60</startupDelay>
      <interval>120</interval>
      <timeout>30</timeout>
      <consolidator>default</consolidator>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Active head node with NMX-X settings</name>
        <resources>Active</resources>
        <resources>NMXM</resources>
        <op>AND</op>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>ilo</name>
      <description>Samples metrics of HP's iLO device</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_ilo]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <fuzzyOffset>1.0</fuzzyOffset>
      <consolidator>default</consolidator>
      <introduceNaN>no</introduceNaN>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>ilo</name>
        <resources>ilo</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>ipmi</name>
      <description>Samples metrics of IPMI devices</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_ipmi]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <fuzzyOffset>1.0</fuzzyOffset>
      <consolidator>default</consolidator>
      <introduceNaN>no</introduceNaN>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Active head node</name>
        <resources>Active</resources>
      </MonitoringExecutionFilter>
      <MonitoringExecutionMultiplexer>
        <childType>MonitoringResourceExecutionMultiplexer</childType>
        <name>ipmi</name>
        <resources>ipmi</resources>
        <resources>drac</resources>
      </MonitoringExecutionMultiplexer>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>cimc</name>
      <description>Samples metrics of Cisco CIMC devices</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/ucsmetrics]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <fuzzyOffset>1.0</fuzzyOffset>
      <consolidator>default</consolidator>
      <introduceNaN>no</introduceNaN>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Active head node</name>
        <resources>Active</resources>
      </MonitoringExecutionFilter>
      <MonitoringExecutionMultiplexer>
        <childType>MonitoringResourceExecutionMultiplexer</childType>
        <name>cimc</name>
        <resources>cimc</resources>
      </MonitoringExecutionMultiplexer>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>redfish</name>
      <description>Samples metrics of Redfish BMC devices</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_redfish.py]]></script>
      <maxSamples>4096</maxSamples>
      <maxMeasurables>65536</maxMeasurables>
      <interval>300</interval>
      <timeout>240</timeout>
      <fuzzyOffset>1.0</fuzzyOffset>
      <consolidator>default</consolidator>
      <introduceNaN>no</introduceNaN>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Active head node</name>
        <resources>Active</resources>
      </MonitoringExecutionFilter>
      <MonitoringExecutionMultiplexer>
        <childType>MonitoringResourceExecutionMultiplexer</childType>
        <name>Redfish</name>
        <resources>redfish</resources>
        <op>AND</op>
      </MonitoringExecutionMultiplexer>
      <MonitoringExecutionMultiplexer>
        <childType>MonitoringTypeExecutionMultiplexer</childType>
        <name>Physical nodes</name>
        <types>PhysicalNode</types>
        <types>Switch</types>
      </MonitoringExecutionMultiplexer>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>redfish_power_shelf</name>
      <description>Samples metrics of Redfish power shelf devices</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_power_shelf]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>110</timeout>
      <fuzzyOffset>1.0</fuzzyOffset>
      <consolidator>default</consolidator>
      <introduceNaN>no</introduceNaN>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Active head node</name>
        <resources>Active</resources>
      </MonitoringExecutionFilter>
      <MonitoringExecutionMultiplexer>
        <childType>MonitoringResourceExecutionMultiplexer</childType>
        <name>Redfish</name>
        <resources>redfish</resources>
        <op>AND</op>
      </MonitoringExecutionMultiplexer>
      <MonitoringExecutionMultiplexer>
        <childType>MonitoringTypeExecutionMultiplexer</childType>
        <name>All power shelves</name>
        <types>PowerShelf</types>
      </MonitoringExecutionMultiplexer>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>redfish_leak</name>
      <description>Samples leak metrics of Redfish BMC devices</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_leak_detection]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>110</timeout>
      <fuzzyOffset>1.0</fuzzyOffset>
      <consolidator>default</consolidator>
      <introduceNaN>no</introduceNaN>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Active head node</name>
        <resources>Active</resources>
      </MonitoringExecutionFilter>
      <MonitoringExecutionMultiplexer>
        <childType>MonitoringResourceExecutionMultiplexer</childType>
        <name>Redfish</name>
        <resources>redfish</resources>
        <op>AND</op>
      </MonitoringExecutionMultiplexer>
      <MonitoringExecutionMultiplexer>
        <childType>MonitoringTypeExecutionMultiplexer</childType>
        <name>Physical nodes</name>
        <types>PhysicalNode</types>
      </MonitoringExecutionMultiplexer>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>raritan</name>
      <description>Samples metrics for Raritan PDU devices</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_raritan]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <fuzzyOffset>1.0</fuzzyOffset>
      <consolidator>default</consolidator>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Active head node</name>
        <resources>Active</resources>
      </MonitoringExecutionFilter>
      <MonitoringExecutionMultiplexer>
        <childType>MonitoringResourceExecutionMultiplexer</childType>
        <name>raritan</name>
        <resources>raritan</resources>
      </MonitoringExecutionMultiplexer>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>NFS</name>
      <description>Samples metrics of storage nodes using nfsstat</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_nfs_metric]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <consolidator>default</consolidator>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Storage</name>
        <resources>Storage</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>mic</name>
      <description>Samples metrics of mics</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_mic]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <consolidator>default</consolidator>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>MIC</name>
        <resources>MIC</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>Xilinx FPGA</name>
      <description>Samples metrics of Xilinx FPGAs</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_fpga_xilinx.py]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <consolidator>default</consolidator>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Xilinx FPGA</name>
        <resources>Xilinx FPGA</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>Intel FPGA</name>
      <description>Samples metrics of Intel FPGAs</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_fpga_intel.py]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <consolidator>default</consolidator>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Intel FPGA</name>
        <resources>Intel FPGA</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>opahfimetric</name>
      <description>Metric collection of Intel OPA HFI</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/opahfimetric]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <consolidator>default</consolidator>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>IB</name>
        <resources>IB</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>opafabricmetric</name>
      <description>Metric collection of Intel OPA Fabric</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/opafabricmetric]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <consolidator>default</consolidator>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>IB</name>
        <resources>IB</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>sample_sys_class_net</name>
      <description>Samples /sys/device/net metrics</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_sys_class_net.py]]></script>
      <maxMeasurables>16384</maxMeasurables>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <consolidator>default</consolidator>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>infiniband</name>
      <description>Samples metrics of InfiniBand interfaces</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_infiniband.py]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <consolidator>default</consolidator>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>IB</name>
        <resources>IB</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerSingleLineMetricScript</childType>
      <name>node_infiniband_link_downed_total</name>
      <description>Samples InfiniBand linked down totals</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/node_infiniband_link_downed_total.sh]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>10</timeout>
      <consolidator>default</consolidator>
      <typeClass>Network/InfiniBand</typeClass>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>IB</name>
        <resources>IB</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerSingleLineMetricScript</childType>
      <name>node_network_carrier_changes_total</name>
      <description>Samples total network carrier changes</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/node_network_carrier_changes_total.sh]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>10</timeout>
      <typeClass>Network</typeClass>
      <consolidator>default</consolidator>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerSingleLineHealthCheckScript</childType>
      <name>Kill ssh sessions</name>
      <description>Kill ssh sessions for users without jobs</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/kill-no-job-user-ssh-sessions]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <consolidator>none</consolidator>
      <typeClass>Workload</typeClass>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Allow ssh only when job is running</name>
        <resources>WLMClient</resources>
        <resources>ssh-only-when-job-running</resources>
        <op>AND</op>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerSingleLineHealthCheckScript</childType>
      <name>cm-chroot-sw-img</name>
      <description>Check for dangling mounts left behind of images created by cm-chroot-sw-img</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/cm-chroot-sw-img]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>10</timeout>
      <consolidator>none</consolidator>
      <typeClass>OS</typeClass>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Provisioning nodes</name>
        <resources>provisioning</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <!-- smart is default for 8.2, but also installed for 8.0, 8.1 -->
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>smart</name>
      <description>Samples SMART data of disks</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_smart]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <consolidator>default</consolidator>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerPrometheus</childType>
      <name>kubemetrics</name>
      <urls><![CDATA[https://${CMD_IP}:${CMD_PORT}/metrics/kubemetrics]]></urls>
      <startupDelay>60</startupDelay>
      <interval>120</interval>
      <timeout>60</timeout>
      <passEnvironment>yes</passEnvironment>
      <consolidator>none</consolidator>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Kube</name>
        <resources>kubelet</resources>
        <resources>kubernetes-worker</resources>
        <op>AND</op>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerPrometheus</childType>
      <name>kubestatemetrics</name>
      <urls><![CDATA[https://${CMD_IP}:${CMD_PORT}/metrics/kubestatemetrics]]></urls>
      <startupDelay>60</startupDelay>
      <interval>120</interval>
      <timeout>60</timeout>
      <passEnvironment>yes</passEnvironment>
      <consolidator>none</consolidator>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Kube</name>
        <resources>kubelet</resources>
        <resources>kubernetes-worker</resources>
        <op>AND</op>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerSingleLineHealthCheckScript</childType>
      <name>ssh2node</name>
      <description>Checks whether master can login on node via ssh, without password</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/ssh2node]]></script>
      <timeout>15</timeout>
      <maxSamples>4096</maxSamples>
      <interval>600</interval>
      <fuzzyOffset>1.0</fuzzyOffset>
      <consolidator>none</consolidator>
      <typeClass>network</typeClass>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Active head node</name>
        <resources>Active</resources>
      </MonitoringExecutionFilter>
      <MonitoringExecutionMultiplexer>
        <childType>MonitoringTypeExecutionMultiplexer</childType>
        <name>All nodes</name>
        <types>Node</types>
        <types>UnmanagedNode</types>
      </MonitoringExecutionMultiplexer>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>gpu-recovery-action</name>
      <description>Samples recovery actions of GPUs</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/gpu-recovery-action]]></script>
      <maxSamples>4096</maxSamples>
      <startupDelay>60</startupDelay>
      <interval>120</interval>
      <timeout>10</timeout>
      <consolidator>default</consolidator>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>GPU</name>
        <resources>GPU</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <healthcheck>
      <name>interfaces</name>
      <description>Compares current settings of ethernet interface against supported. Notice, that for BMC interfaces this check does not check the health status of the actual BMC hardware.</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/interfaces]]></command>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>network</classofhealthcheck>
      <permission>required</permission>
    </healthcheck>
    <healthcheck>
      <name>opalinkhealth</name>
      <description>Checks the quality and the integrity error of Intel OPA HFI link.</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/opalinkhealth]]></command>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>network</classofhealthcheck>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>IB</name>
        <resources>IB</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>dmesg</name>
      <description>Check whether certain regular expressions have been found in the output of dmesg (then this check returns FAIL)</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/dmesg]]></command>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>operatingsystem</classofhealthcheck>
    </healthcheck>
    <healthcheck>
      <name>ib</name>
      <description>Check which inspects whether the cmdaemon defined infiniband interfaces are working properly</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/ib]]></command>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>operatingsystem</classofhealthcheck>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>IB</name>
        <resources>IB</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>oomkiller</name>
      <description>Checks whether oomkiller has come into action (then this check returns FAIL)</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/oomkiller]]></command>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>operatingsystem</classofhealthcheck>
    </healthcheck>
    <healthcheck>
      <name>hardware-profile</name>
      <description>Checks hardware of a node against predefined profile</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/node-hardware-profile]]></command>
      <disabled/>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>misc</classofhealthcheck>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Active head node</name>
        <resources>Active</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>cmsh</name>
      <description>Checks whether cmsh is available, i.e. can we use cmsh for the default cluster?</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/cmsh]]></command>
      <startupDelay>60</startupDelay>
      <interval>1800</interval>
      <offset>60</offset>
      <timeout>20</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>internal</classofhealthcheck>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Active head node</name>
        <resources>Active</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>exports</name>
      <description>Checks whether all filesystems are exported as defined by the cluster management system</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/exports]]></command>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>disk</classofhealthcheck>
      <extendedenvironment/>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Storage</name>
        <resources>storage</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>cuda-dcgm</name>
      <description>Checks whether cuda-dcgm service is running if there are GPUS</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/cuda-dcgm]]></command>
      <startupDelay>60</startupDelay>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>operatingsystem</classofhealthcheck>
    </healthcheck>
    <healthcheck>
      <name>cmha-status</name>
      <interval>1800</interval>
      <startupDelay>60</startupDelay>
      <description>Checks the HA status, i.e., all both up and running?</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/cmha-status]]></command>
      <timeout>20</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>internal</classofhealthcheck>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Failover nodes</name>
        <resources>Failover</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>ldap</name>
      <description>Checks the functionality of ldap, i.e. can we lookup the id of the user (using ldap)</description>
      <startupDelay>120</startupDelay>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/ldap]]></command>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>operatingsystem</classofhealthcheck>
    </healthcheck>
    <healthcheck>
      <name>mounts</name>
      <description>Checks whether all mounts which are defined in cluster manager are correct</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/mounts]]></command>
      <startupDelay>60</startupDelay>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>disk</classofhealthcheck>
      <extendedenvironment/>
    </healthcheck>
    <healthcheck>
      <name>mysql</name>
      <description>Checks whether the mysql cmdaemon tables are in a good state</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/mysql]]></command>
      <startupDelay>900</startupDelay>
      <interval>14400</interval>
      <timeout>300</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>operatingsystem</classofhealthcheck>
      <MonitoringExecutionFilter>
        <childType>MonitoringTypeExecutionFilter</childType>
        <name>Head nodes</name>
        <headNode/>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>rogueprocess</name>
      <description>finds user processes which are 'rogue', illegal</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/rogueprocess]]></command>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>workload</classofhealthcheck>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Workload clients</name>
        <resources>SlurmClient</resources>
        <resources>UGEClient</resources>
        <resources>LSFClient</resources>
        <resources>PbsProClient</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>diskspace</name>
      <description>checks free disk space</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/diskspace]]></command>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>disk</classofhealthcheck>
    </healthcheck>
    <healthcheck>
      <name>swraid</name>
      <description>checks status of software raid disk devices</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/swraid]]></command>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>disk</classofhealthcheck>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Software RAID</name>
        <resources>swraid</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>ntp</name>
      <description>checks time</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/ntp]]></command>
      <startupDelay>60</startupDelay>
      <timeout>20</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>internal</classofhealthcheck>
    </healthcheck>
    <healthcheck>
      <name>lustre</name>
      <description>checks status of Lustre filesystems</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/lustre]]></command>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>disk</classofhealthcheck>
    </healthcheck>
    <healthcheck>
      <name>schedulers</name>
      <startupDelay>60</startupDelay>
      <description>checks whether the queue instances of all schedulers on a node are healthy</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/schedulers]]></command>
      <timeout>10</timeout>
      <fuzzyOffset>1.0</fuzzyOffset>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>workload</classofhealthcheck>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Workload clients</name>
        <resources>SlurmClient</resources>
        <resources>UGEClient</resources>
        <resources>LSFClient</resources>
        <resources>PbsProClient</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>failedprejob</name>
      <description>Checks whether prejob checks have failed</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/failedprejob]]></command>
      <timeout>10</timeout>
      <stateflappingcount>99</stateflappingcount>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>workload</classofhealthcheck>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Nodes with a WLM client and prejob enabled</name>
        <resources>PreJob</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>chrootprocess</name>
      <description>Checks for daemon processes running (chroot) in software images</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/chrootprocess]]></command>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>operatingsystem</classofhealthcheck>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Provisioning</name>
        <resources>Provisioning</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>hpraid</name>
      <description>checks status of HP Smart Array controllers</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/hpraid]]></command>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>disk</classofhealthcheck>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>HP RAID</name>
        <resources>hpraid</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>megaraid</name>
      <description>checks status of MegaRaid controllers</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/megaraid]]></command>
      <timeout>10</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>disk</classofhealthcheck>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Mega RAID</name>
        <resources>megaraid</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>defaultgateway</name>
      <description>checks if the default gateway is reachable</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/defaultgateway]]></command>
      <timeout>10</timeout>
      <fuzzyOffset>1.0</fuzzyOffset>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>network</classofhealthcheck>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>DisableInAzure</name>
        <resources>AzureCloudNode</resources>
        <filterOperation>EXCLUDE</filterOperation>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>gpuhealth_quick</name>
      <description>checks health of gpus</description>
      <command><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/gpuhealth_quick]]></command>
      <startupDelay>60</startupDelay>
      <timeout>30</timeout>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>GPU</classofhealthcheck>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>GPU</name>
        <headNode/>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>Docker</name>
      <description>Checks whether the docker service is healthy</description>
      <command>/cm/local/apps/cmd/scripts/healthchecks/docker</command>
      <timeout>10</timeout>
      <startupDelay>60</startupDelay>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>Docker</classofhealthcheck>
      <MonitoringExecutionFilter>
        <name>Resources</name>
        <revision/>
        <childType>MonitoringResourceExecutionFilter</childType>
        <resources>Docker::Host</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>KubernetesComponentsStatus</name>
      <description>Checks the kubernetes cluster components</description>
      <command>/cm/local/apps/cmd/scripts/healthchecks/kubernetescomponentsstatus</command>
      <timeout>10</timeout>
      <startupDelay>60</startupDelay>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>Kubernetes</classofhealthcheck>
      <MonitoringExecutionFilter>
        <name>Resources</name>
        <revision/>
        <childType>MonitoringResourceExecutionFilter</childType>
        <resources>kubelet</resources>
        <resources>kubernetes-control-plane</resources>
        <op>AND</op>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>KubernetesNodesStatus</name>
      <description>Checks the kubernetes nodes status</description>
      <command>/cm/local/apps/cmd/scripts/healthchecks/kubernetesnodesstatus</command>
      <timeout>10</timeout>
      <startupDelay>60</startupDelay>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>Kubernetes</classofhealthcheck>
      <MonitoringExecutionFilter>
        <name>Resources</name>
        <revision/>
        <childType>MonitoringResourceExecutionFilter</childType>
        <resources>kubelet</resources>
        <resources>kubernetes-control-plane</resources>
        <op>AND</op>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>KubernetesPodsStatus</name>
      <description>Checks the kubernetes pods status</description>
      <command>/cm/local/apps/cmd/scripts/healthchecks/kubernetespodsstatus</command>
      <timeout>10</timeout>
      <startupDelay>60</startupDelay>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>Kubernetes</classofhealthcheck>
      <MonitoringExecutionFilter>
        <name>Resources</name>
        <revision/>
        <childType>MonitoringResourceExecutionFilter</childType>
        <resources>kubelet</resources>
        <resources>kubernetes-control-plane</resources>
        <op>AND</op>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>KubernetesChildNode</name>
      <description>Checks the kubelet service health</description>
      <command>/cm/local/apps/cmd/scripts/healthchecks/kuberneteschildnode</command>
      <timeout>10</timeout>
      <startupDelay>60</startupDelay>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>Kubernetes</classofhealthcheck>
      <MonitoringExecutionFilter>
        <name>Resources</name>
        <revision/>
        <childType>MonitoringResourceExecutionFilter</childType>
        <resources>kubelet</resources>
        <resources>kubernetes-worker</resources>
        <op>AND</op>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>KubernetesCertsExpiration</name>
      <description>Checks Kubernetes for expiring Certificates</description>
      <command>/cm/local/apps/cmd/scripts/healthchecks/kubernetescertsexpiration</command>
      <timeout>50</timeout>
      <startupDelay>60</startupDelay>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>Kubernetes</classofhealthcheck>
      <MonitoringExecutionFilter>
        <name>Resources</name>
        <revision/>
        <childType>MonitoringResourceExecutionFilter</childType>
        <resources>kubelet</resources>
        <resources>kubernetes-control-plane</resources>
        <op>AND</op>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>Etcd</name>
      <description>Checks the etcd service health</description>
      <command>/cm/local/apps/cmd/scripts/healthchecks/etcd</command>
      <timeout>20</timeout>
      <startupDelay>60</startupDelay>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>Etcd</classofhealthcheck>
      <MonitoringExecutionFilter>
        <name>Resources</name>
        <revision/>
        <childType>MonitoringResourceExecutionFilter</childType>
        <resources>Etcd::Host</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <healthcheck>
      <name>DockerRegistry</name>
      <description>Checks the docker-registry service health</description>
      <command>/cm/local/apps/cmd/scripts/healthchecks/dockerregistry</command>
      <timeout>10</timeout>
      <startupDelay>60</startupDelay>
      <samplingmethod>samplingonslave</samplingmethod>
      <classofhealthcheck>Docker</classofhealthcheck>
      <MonitoringExecutionFilter>
        <name>Resources</name>
        <revision/>
        <childType>MonitoringResourceExecutionFilter</childType>
        <resources>Docker::Registry</resources>
      </MonitoringExecutionFilter>
    </healthcheck>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>license-count</name>
      <description>Samples licensed and used nodes counts</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/license_count]]></script>
      <maxSamples>32768</maxSamples>
      <interval>3600</interval>
      <timeout>10</timeout>
      <consolidator>default</consolidator>
      <introduceNaN>no</introduceNaN>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Active head node</name>
        <resources>Active</resources>
      </MonitoringExecutionFilter>
      <MonitoringExecutionMultiplexer>
        <childType>MonitoringTypeExecutionMultiplexer</childType>
        <name>Partition</name>
        <types>Partition</types>
      </MonitoringExecutionMultiplexer>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>slurm-state-count</name>
      <description>Samples the number of nodes in a particular node state</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/slurm_states.py]]></script>
      <startupDelay>60</startupDelay>
      <interval>120</interval>
      <timeout>30</timeout>
      <consolidator>default</consolidator>
      <introduceNaN>no</introduceNaN>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Active head node</name>
        <resources>Active</resources>
      </MonitoringExecutionFilter>
      <MonitoringExecutionMultiplexer>
        <childType>MonitoringTypeExecutionMultiplexer</childType>
        <name>SlurmWlmCluster</name>
        <types>SlurmWlmCluster</types>
      </MonitoringExecutionMultiplexer>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerScript</childType>
      <name>liteon_redfish</name>
      <description>Samples metrics of LiteOn power shelf</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/metrics/sample_liteon]]></script>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <consolidator>default</consolidator>
      <introduceNaN>no</introduceNaN>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>Active head node</name>
        <resources>Active</resources>
      </MonitoringExecutionFilter>
      <MonitoringExecutionMultiplexer>
        <childType>MonitoringResourceExecutionMultiplexer</childType>
        <name>liteon</name>
        <resources>liteon</resources>
      </MonitoringExecutionMultiplexer>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerSingleLineHealthCheckScript</childType>
      <name>nvsm_show_health</name>
      <description>Checks health of DGX system</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/nvsm_show_health]]></script>
      <startupDelay>60</startupDelay>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <typeClass>NVSM</typeClass>
      <consolidator>none</consolidator>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>NVSM</name>
        <resources>NVSM</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
    <MonitoringDataProducer>
      <childType>MonitoringDataProducerSingleLineHealthCheckScript</childType>
      <name>nvsm_pci_health</name>
      <description>Checks health of PCI devices in a DGX system</description>
      <script><![CDATA[/cm/local/apps/cmd/scripts/healthchecks/nvsm_pci_health]]></script>
      <startupDelay>60</startupDelay>
      <maxSamples>4096</maxSamples>
      <interval>120</interval>
      <timeout>30</timeout>
      <typeClass>NVSM</typeClass>
      <consolidator>none</consolidator>
      <MonitoringExecutionFilter>
        <childType>MonitoringResourceExecutionFilter</childType>
        <name>NVSM</name>
        <resources>NVSM</resources>
      </MonitoringExecutionFilter>
    </MonitoringDataProducer>
  </Monitoring>
  <isoname>UBUNTU2404</isoname>
  <stableversion>11.0-stable</stableversion>
</Cluster>
