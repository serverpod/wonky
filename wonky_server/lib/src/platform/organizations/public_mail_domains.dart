/// Mail domains that never form an organization (specs/04 §6.1): public
/// and free mail providers, privacy relays, disposable addresses and names
/// reserved for documentation and tests. Users with such an address have no
/// organization and are shared with by their full email only.
///
/// Deployments add domains with `wonky: organizations: publicDomains:`.
abstract final class PublicMailDomains {
  /// Brands whose domain is public under every country or generic ending
  /// (`hotmail.co.uk`, `yahoo.com.br`, `gmx.at`, `live.fr`, …).
  static const brands = {
    'aol',
    'gmail',
    'gmx',
    'googlemail',
    'hotmail',
    'icloud',
    'live',
    'msn',
    'outlook',
    'protonmail',
    'rocketmail',
    'windowslive',
    'yahoo',
    'yandex',
    'ymail',
    'zoho',
  };

  /// Top-level names reserved by RFC 2606 / RFC 6761 and mDNS: no real
  /// organization lives there (the test users are `@example.test`).
  static const reservedTlds = {
    'example',
    'invalid',
    'local',
    'localhost',
    'test',
  };

  /// Individual public domains.
  static const domains = {
    // Global providers.
    'aim.com', 'aol.com', 'gmail.com', 'googlemail.com', 'hotmail.com',
    'icloud.com', 'live.com', 'mac.com', 'me.com', 'msn.com',
    'outlook.com', 'passport.com', 'rocketmail.com', 'windowslive.com',
    'yahoo.com', 'ymail.com', 'mail.com', 'email.com', 'usa.com',
    'myself.com', 'consultant.com', 'post.com', 'europe.com', 'asia.com',
    'engineer.com', 'iname.com', 'writeme.com', 'inbox.com', 'zoho.com',
    'zohomail.com', 'zohomail.eu', 'yandex.com', 'yandex.ru', 'ya.ru',
    'hey.com', 'fastmail.com', 'fastmail.fm', 'fastmail.net', 'fastmail.to',
    'mailfence.com', 'runbox.com', 'startmail.com', 'lavabit.com',
    'hushmail.com', 'hush.com', 'countermail.com', 'kolabnow.com',
    'mailbox.org', 'posteo.de', 'posteo.net', 'disroot.org', 'riseup.net',
    'cock.li', 'airmail.cc', 'tutanota.com', 'tutanota.de', 'tutamail.com',
    'tuta.io', 'tuta.com', 'keemail.me', 'proton.me', 'protonmail.com',
    'protonmail.ch', 'pm.me', 'gmx.com', 'gmx.net', 'gmx.de', 'gmx.at',
    'gmx.ch', 'gmx.fr', 'gmx.us', 'gmx.co.uk',
    // Privacy relays and aliases.
    'duck.com', 'privaterelay.appleid.com', 'simplelogin.com',
    'simplelogin.co', 'slmail.me', 'aleeas.com', 'anonaddy.com',
    'anonaddy.me', 'addy.io', 'relay.firefox.com', 'mozmail.com',
    'passmail.net', 'passinbox.com', 'users.noreply.github.com',
    // Disposable addresses.
    'mailinator.com', 'guerrillamail.com', 'guerrillamail.net',
    'sharklasers.com', 'grr.la', '10minutemail.com', 'temp-mail.org',
    'tempmail.com', 'yopmail.com', 'yopmail.fr', 'trashmail.com',
    'getnada.com', 'maildrop.cc', 'dispostable.com', 'throwawaymail.com',
    'mailnesia.com', 'mintemail.com', 'emailondeck.com', 'spamgourmet.com',
    // Europe.
    'web.de', 't-online.de', 'freenet.de', 'arcor.de', 'online.de',
    'email.de', 'vodafone.de', '1und1.de', 'mail.de', 'gmx.li',
    'bluewin.ch', 'hispeed.ch', 'sunrise.ch', 'aon.at', 'chello.at',
    'chello.nl', 'ziggo.nl', 'kpnmail.nl', 'kpnplanet.nl', 'home.nl',
    'planet.nl', 'hetnet.nl', 'xs4all.nl', 'telenet.be', 'skynet.be',
    'proximus.be', 'orange.fr', 'wanadoo.fr', 'free.fr', 'sfr.fr',
    'neuf.fr', 'laposte.net', 'bbox.fr', 'numericable.fr', 'libero.it',
    'virgilio.it', 'tiscali.it', 'alice.it', 'tim.it', 'fastwebnet.it',
    'tin.it', 'inwind.it', 'email.it', 'terra.es', 'telefonica.net',
    'movistar.es', 'ono.com', 'sapo.pt', 'clix.pt', 'netcabo.pt',
    'btinternet.com', 'btopenworld.com', 'sky.com', 'virginmedia.com',
    'virgin.net', 'talktalk.net', 'tiscali.co.uk', 'ntlworld.com',
    'blueyonder.co.uk', 'o2.co.uk', 'orange.net', 'eircom.net',
    'seznam.cz', 'centrum.cz', 'email.cz', 'post.cz', 'volny.cz',
    'atlas.cz', 'azet.sk', 'centrum.sk', 'zoznam.sk', 'wp.pl', 'o2.pl',
    'onet.pl', 'onet.eu', 'interia.pl', 'interia.eu', 'op.pl', 'poczta.fm',
    'gazeta.pl', 'tlen.pl', 'freemail.hu', 'citromail.hu', 'indamail.hu',
    'abv.bg', 'mail.bg', 'dir.bg', 'yahoo.ro', 'telia.com', 'telia.se',
    'bredband.net', 'comhem.se', 'spray.se', 'home.se', 'tele2.se',
    'online.no', 'telenet.no', 'start.no', 'frisurf.no', 'jubii.dk',
    'mail.dk', 'tdcadsl.dk', 'ofir.dk', 'suomi24.fi', 'luukku.com',
    'kolumbus.fi', 'elisanet.fi', 'saunalahti.fi', 'mail.ee', 'inbox.lv',
    'inbox.lt', 'mail.ru', 'bk.ru', 'list.ru', 'inbox.ru', 'internet.ru',
    'rambler.ru', 'lenta.ru', 'autorambler.ru', 'ukr.net', 'i.ua',
    'meta.ua', 'bigmir.net', 'tut.by', 'mail.by',
    // Americas.
    'comcast.net', 'verizon.net', 'att.net', 'sbcglobal.net',
    'bellsouth.net', 'cox.net', 'charter.net', 'earthlink.net', 'juno.com',
    'netzero.net', 'netzero.com', 'optonline.net', 'optimum.net',
    'frontier.com', 'frontiernet.net', 'windstream.net', 'centurylink.net',
    'q.com', 'roadrunner.com', 'rr.com', 'twc.com', 'spectrum.net',
    'mindspring.com', 'pacbell.net', 'prodigy.net', 'ameritech.net',
    'flash.net', 'swbell.net', 'snet.net', 'wowway.com', 'mediacombb.net',
    'suddenlink.net', 'embarqmail.com', 'shaw.ca', 'rogers.com',
    'sympatico.ca', 'bell.net', 'telus.net', 'videotron.ca', 'cogeco.ca',
    'eastlink.ca', 'terra.com.br', 'bol.com.br', 'uol.com.br', 'ig.com.br',
    'globo.com', 'globomail.com', 'r7.com', 'oi.com.br', 'zipmail.com.br',
    'prodigy.net.mx', 'infinitum.com.mx', 'speedy.com.ar', 'fibertel.com.ar',
    'arnet.com.ar', 'ciudad.com.ar', 'vtr.net', 'entelchile.net',
    // Asia and Oceania.
    'qq.com', 'foxmail.com', '163.com', '126.com', 'yeah.net', '188.com',
    'vip.163.com', 'vip.qq.com', 'sina.com', 'sina.cn', 'sohu.com',
    'aliyun.com', '139.com', '189.cn', 'wo.cn', 'tom.com', '21cn.com',
    'naver.com', 'daum.net', 'hanmail.net', 'nate.com', 'kakao.com',
    'docomo.ne.jp', 'ezweb.ne.jp', 'au.com', 'softbank.ne.jp',
    'i.softbank.jp', 'nifty.com', 'biglobe.ne.jp', 'ocn.ne.jp', 'so-net.ne.jp',
    'rediffmail.com', 'sify.com', 'indiatimes.com', 'vsnl.net',
    'bigpond.com', 'bigpond.net.au', 'optusnet.com.au', 'telstra.com',
    'iinet.net.au', 'internode.on.net', 'tpg.com.au', 'westnet.com.au',
    'dodo.com.au', 'xtra.co.nz', 'slingshot.co.nz', 'clear.net.nz',
    'paradise.net.nz', 'singnet.com.sg', 'pacific.net.sg', 'streamyx.com',
    'pd.jaring.my', 'netvigator.com', 'hknet.com', 'ymail.co.in',
    // Africa and the Middle East.
    'mweb.co.za', 'telkomsa.net', 'webmail.co.za', 'vodamail.co.za',
    'iafrica.com', 'afrihost.co.za', 'menara.ma', 'walla.co.il',
    'walla.com', 'netvision.net.il', 'bezeqint.net', 'zahav.net.il',
  };

  /// Generic second-level labels under country endings.
  static const _secondLevel = {'co', 'com', 'net', 'org', 'ne', 'or'};

  static final _valid = RegExp(r'^[a-z0-9-]+(\.[a-z0-9-]+)+$');

  /// Whether [domain] (lowercase) is public or reserved. A malformed domain
  /// counts as public: it never forms an organization.
  static bool isPublic(String domain) {
    if (!_valid.hasMatch(domain)) return true;
    if (domains.contains(domain)) return true;
    final labels = domain.split('.');
    if (reservedTlds.contains(labels.last)) return true;
    if (labels.length >= 2 &&
        labels[labels.length - 2] == 'example' &&
        const {'com', 'net', 'org'}.contains(labels.last)) {
      return true;
    }
    // `<brand>.<tld>` or `<brand>.<co|com|…>.<country>`: hotmail.co.uk,
    // yahoo.com.br, gmx.at, live.fr.
    if (!brands.contains(labels.first)) return false;
    if (labels.length == 2) return true;
    return labels.length == 3 &&
        _secondLevel.contains(labels[1]) &&
        labels[2].length == 2;
  }
}
