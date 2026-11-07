import 'package:test/test.dart';
import 'package:wonky_server/src/platform/organizations/organization_config.dart';
import 'package:wonky_server/src/platform/organizations/organization_service.dart';
import 'package:wonky_server/src/platform/organizations/public_mail_domains.dart';

/// Organizations from verified email domains (specs/04 §6).
void main() {
  final config = OrganizationConfig(
    aliases: [
      ['serverpod.dev', 'serverpod.com'],
    ],
  );

  Organization? orgOf(String email) =>
      OrganizationService.forEmail(email, config);

  group('Given a company domain', () {
    test('when two users share it then they are one organization', () {
      expect(orgOf('anna@acme.dev'), isNotNull);
      expect(orgOf('anna@acme.dev'), orgOf('bo@ACME.dev'));
      expect(orgOf('anna@acme.dev')!.key, 'acme.dev');
    });

    test('when the domains differ then the organizations differ', () {
      expect(orgOf('anna@acme.dev'), isNot(orgOf('bo@globex.dev')));
    });

    test('when a subdomain is used then it is its own organization', () {
      expect(orgOf('anna@eu.acme.dev')!.key, 'eu.acme.dev');
      expect(orgOf('anna@eu.acme.dev'), isNot(orgOf('bo@acme.dev')));
    });
  });

  group('Given an alias group', () {
    test('when users are on either domain then they are one organization', () {
      final dev = orgOf('anna@serverpod.dev')!;
      final com = orgOf('bo@serverpod.com')!;

      expect(dev, com);
      expect(com.key, 'serverpod.dev');
      expect(com.domains, ['serverpod.dev', 'serverpod.com']);
    });

    test('when the key is read back from a grant then it resolves', () {
      expect(
        OrganizationService.forEmail('x@serverpod.com', config)?.key,
        'serverpod.dev',
      );
    });
  });

  group('Given public and reserved domains', () {
    for (final email in [
      'a@gmail.com',
      'a@googlemail.com',
      'a@outlook.com',
      'a@hotmail.co.uk',
      'a@hotmail.fr',
      'a@live.se',
      'a@icloud.com',
      'a@me.com',
      'a@yahoo.com',
      'a@yahoo.co.jp',
      'a@yahoo.com.br',
      'a@proton.me',
      'a@protonmail.com',
      'a@pm.me',
      'a@gmx.de',
      'a@gmx.at',
      'a@aol.com',
      'a@web.de',
      'a@qq.com',
      'a@mail.ru',
      'a@duck.com',
      'a@privaterelay.appleid.com',
      'a@mailinator.com',
      'a@example.test',
      'a@users.invalid',
      'a@example.com',
      'a@host.localhost',
    ]) {
      test('when the address is $email then there is no organization', () {
        expect(orgOf(email), isNull);
      });
    }

    test('when a company domain merely starts like a brand then it is '
        'an organization', () {
      expect(orgOf('a@mail.acme.com'), isNotNull);
      expect(orgOf('a@yahoo-fans.org'), isNotNull);
      expect(PublicMailDomains.isPublic('outlook.acme.io'), isFalse);
    });

    test('when the address is malformed then there is no organization', () {
      expect(orgOf('not-an-email'), isNull);
      expect(orgOf('a@'), isNull);
      expect(orgOf("a@x'); drop table x;--.com"), isNull);
    });

    test(
      'when a domain is configured as public then it has no organization',
      () {
        final c = OrganizationConfig(publicDomains: {'Mail.Example.Org'});

        expect(OrganizationService.forEmail('a@mail.example.org', c), isNull);
        expect(OrganizationService.forEmail('a@acme.dev', c), isNotNull);
      },
    );

    test('when an alias group contains a public domain then it is ignored', () {
      final c = OrganizationConfig(
        aliases: [
          ['acme.dev', 'gmail.com'],
        ],
      );

      expect(OrganizationService.forEmail('a@gmail.com', c), isNull);
      expect(OrganizationService.forEmail('a@acme.dev', c)!.domains, [
        'acme.dev',
      ]);
    });
  });

  group('Given organizations are disabled', () {
    test('when asking for an organization then there is none', () {
      final c = OrganizationConfig(enabled: false);

      expect(OrganizationService.forEmail('a@acme.dev', c), isNull);
    });
  });

  group('Given the configuration map', () {
    test('when it is read then domains and aliases are parsed', () {
      final c = OrganizationConfig.fromMap({
        'publicDomains': ['isp.example'],
        'aliases': [
          ['a.dev', 'a.com'],
        ],
      });

      expect(c.enabled, isTrue);
      expect(c.isPublic('isp.example'), isTrue);
      expect(c.domainsOf('a.com'), ['a.dev', 'a.com']);
      expect(c.domainsOf('serverpod.com'), ['serverpod.com']);
    });

    test('when nothing is configured then the production aliases apply', () {
      final c = OrganizationConfig.fromMap({});

      expect(c.domainsOf('serverpod.com'), ['serverpod.dev', 'serverpod.com']);
    });

    test('when environment variables are set then they override the map', () {
      final c = OrganizationConfig.fromMap(
        {'enabled': true},
        environment: {
          'WONKY_ORGANIZATIONS_ENABLED': 'false',
          'WONKY_ORGANIZATIONS_PUBLIC_DOMAINS': 'isp.one,isp.two',
          'WONKY_ORGANIZATIONS_ALIASES': 'x.io,x.com;y.io,y.com',
        },
      );

      expect(c.enabled, isFalse);
      expect(c.isPublic('isp.two'), isTrue);
      expect(c.domainsOf('y.com'), ['y.io', 'y.com']);
    });
  });

  group('Given an organization', () {
    test('when it is inlined into SQL then only its domains appear', () {
      final org = orgOf('a@serverpod.com')!;

      expect(org.sqlList, "'serverpod.dev', 'serverpod.com'");
      expect(
        OrganizationService.sqlMemberCondition('u.email', org),
        "split_part(u.email, '@', 2) IN ('serverpod.dev', 'serverpod.com')",
      );
    });
  });
}
