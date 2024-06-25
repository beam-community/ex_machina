# Changelog

The noteworthy changes for each ExMachina version are included here. For a
complete changelog, see the git history for each version via the version links.

**To see the dates a version was published see the [hex package page].**

[hex package page]: https://hex.pm/packages/ex_machina

## [2.8.0](https://github.com/beam-community/ex_machina/compare/v2.7.0...v2.8.0) (2024-06-24)


### Features

* ExMachina.start/2: return a supervisor from Application callback ([#434](https://github.com/beam-community/ex_machina/issues/434)) ([c9ebb47](https://github.com/beam-community/ex_machina/commit/c9ebb47d7ffecdae3acf22f71c257de8bcdcffdc))


### Bug Fixes

* Revert code changes breaking ecto record loading ([#447](https://github.com/beam-community/ex_machina/issues/447)) ([b796311](https://github.com/beam-community/ex_machina/commit/b796311761413086dac24dd3451ded8c0c349870))


### Miscellaneous

* Add release please manifest file ([ae31578](https://github.com/beam-community/ex_machina/commit/ae31578057b682b6bf7d51d3bb29229e4cbb16c3))
* Clear up log level warning ([821a61a](https://github.com/beam-community/ex_machina/commit/821a61a351676c2fee717451d8881059dc04730d))
* Fix missing , in configuration file ([cf74a91](https://github.com/beam-community/ex_machina/commit/cf74a91a4f0b913b6b96a233692419a030be4cff))
* README updates ([#444](https://github.com/beam-community/ex_machina/issues/444)) ([a4352dd](https://github.com/beam-community/ex_machina/commit/a4352dd59c3ce90d95fe85af65dda9ad332367d1))
* Remove circleci, update tools-version ([#438](https://github.com/beam-community/ex_machina/issues/438)) ([b06f4b6](https://github.com/beam-community/ex_machina/commit/b06f4b6ebe323b8c0b4edcc961fbf4abb5a68bcd))
* Remove extra character from test configuration file ([e8edf47](https://github.com/beam-community/ex_machina/commit/e8edf473c84ba414c5c07c267abac773cb64be6d))
* Resolve config warning ([#440](https://github.com/beam-community/ex_machina/issues/440)) ([a327830](https://github.com/beam-community/ex_machina/commit/a32783031b21cd91bced561d4a30e9031f8a77e9))
* Satisfy Credo consistency check ([5aa4f01](https://github.com/beam-community/ex_machina/commit/5aa4f01c8234a76cb3a41fa43e6da7cbd668ba03))
* Support common-config ([#436](https://github.com/beam-community/ex_machina/issues/436)) ([2c2a309](https://github.com/beam-community/ex_machina/commit/2c2a309532f418083dac0df7bc74bf675056ad28))
* Sync files with beam-community/common-config ([#437](https://github.com/beam-community/ex_machina/issues/437)) ([72e4038](https://github.com/beam-community/ex_machina/commit/72e40389a273a38be5f8dd96aef02976258212aa))
* Sync files with beam-community/common-config ([#441](https://github.com/beam-community/ex_machina/issues/441)) ([c809bce](https://github.com/beam-community/ex_machina/commit/c809bce0db914604b431be8d47d922aae9fe8e3e))
* Sync files with beam-community/common-config ([#448](https://github.com/beam-community/ex_machina/issues/448)) ([cca2acf](https://github.com/beam-community/ex_machina/commit/cca2acfecd66b1002eff2470a42e9302c76f5495))
* Sync files with beam-community/common-config ([#450](https://github.com/beam-community/ex_machina/issues/450)) ([69612ae](https://github.com/beam-community/ex_machina/commit/69612ae19903a9410cc1fbaf9680d070c0b72370))
* Update and run formatter ([#439](https://github.com/beam-community/ex_machina/issues/439)) ([8bb6057](https://github.com/beam-community/ex_machina/commit/8bb605725658a9dc36bd6e1f1579736f4b6514f4))
* Update mix.exs and deps ([c6c76f0](https://github.com/beam-community/ex_machina/commit/c6c76f044d4fe8f57d82daed50800f8d43bd15b2))
* Update test postgres configuration ([6aab2c8](https://github.com/beam-community/ex_machina/commit/6aab2c80cf17a66a0f087e6402b74e5477510884))

## [2.7.0]

[2.7.0]: https://github.com/thoughtbot/ex_machina/compare/v2.6.0...v2.7.0

### Added

- Allow setting sequence starting point (#414)

[#414]: https://github.com/thoughtbot/ex_machina/pull/414

## [2.6.0]

[2.6.0]: https://github.com/thoughtbot/ex_machina/compare/v2.5.0...v2.6.0

### Added

- Pass opts to Repo.insert! (add function-level opts to strategies) ([#411])

### Fixes/Improvements

- Import evaluate_lazy_attributes for ExMachina ([#410])

### Docs

- Use HTTPS for links in README ([#413])
- Remove "web" dir from README.md ([#412])

[#413]: https://github.com/thoughtbot/ex_machina/pull/413
[#412]: https://github.com/thoughtbot/ex_machina/pull/412
[#411]: https://github.com/thoughtbot/ex_machina/pull/411
[#410]: https://github.com/thoughtbot/ex_machina/pull/410

## [2.5.0]

[2.5.0]: https://github.com/thoughtbot/ex_machina/compare/v2.4.0...v2.5.0

### Added

- Allow delayed evaluation of attributes ([#408])

### Fixes

- Fix Elixir 1.11 compiler warnings ([#399])
- Fix Elixir 1.11 warning by using extra_applications ([#400])

### Docs

- Update references to prior art ([#384])
- Bump version number in Readme ([#376])

[#376]: https://github.com/thoughtbot/ex_machina/pull/376
[#384]: https://github.com/thoughtbot/ex_machina/pull/384
[#399]: https://github.com/thoughtbot/ex_machina/pull/399
[#400]: https://github.com/thoughtbot/ex_machina/pull/400
[#408]: https://github.com/thoughtbot/ex_machina/pull/408

## [2.4.0]

### Added

- Allow ExMachina.Ecto to be used without :repo option ([#370])

[2.4.0]: https://github.com/thoughtbot/ex_machina/compare/v2.3.0...v2.4.0
[#370]: https://github.com/thoughtbot/ex_machina/pull/370

## [2.3.0]

### Added

- Allows more control over factory definitions ([#333])
- Adds ability to reset specific sequences ([#331])

### Docs

- Adds additional callbacks for functions with default params ([#319])

## Updated dependencies

- Bump ex_doc from 0.19.1 to 0.19.3
- Bump ecto_sql from 3.0.0 to 3.0.5
- Bump ecto from 3.0.0 to 3.0.5

[2.3.0]: https://github.com/thoughtbot/ex_machina/compare/v2.2.2...v2.3.0
[#333]: https://github.com/thoughtbot/ex_machina/pull/333
[#331]: https://github.com/thoughtbot/ex_machina/pull/331
[#319]: https://github.com/thoughtbot/ex_machina/pull/319

## [2.2.2]

- Adds support for Ecto 3.0 ([#301])

[2.2.2]: https://github.com/thoughtbot/ex_machina/compare/v2.2.1...v2.2.2
[#301]: https://github.com/thoughtbot/ex_machina/pull/301

## [2.2.1]

### Fixed

- Fixes sequence typespec ([#278])

### Removed

- Removed `fields_for/2` function that would raise an error since 1.0.0 ([#287])

### Docs

- Adds example for derived attribute ([#264])
- Adds example for dependent factory ([#239])


[2.2.1]: https://github.com/thoughtbot/ex_machina/compare/v2.2.0...v2.2.1
[#239]: https://github.com/thoughtbot/ex_machina/pull/239
[#264]: https://github.com/thoughtbot/ex_machina/pull/264
[#278]: https://github.com/thoughtbot/ex_machina/pull/278
[#287]: https://github.com/thoughtbot/ex_machina/pull/287

## [2.2.0]

### Added

- Adds support for using lists in sequences ([#227]).

### Fixed

- Elixir 1.6.x changed the behavior of `Regex.split/3` which caused factory
  names to break. Added a fix in ([#275]).

[2.2.0]: https://github.com/thoughtbot/ex_machina/compare/v2.1.0...v2.2.0
[#227]: https://github.com/thoughtbot/ex_machina/pull/227
[#275]: https://github.com/thoughtbot/ex_machina/pull/275

## [2.1.0]

### Added

- Support bare maps in embeds https://github.com/thoughtbot/ex_machina/commit/efd4e7c6125843d20b8dd07d91ded6240ecaf5ef
- Handle nested structures in `string_params_for/2` https://github.com/thoughtbot/ex_machina/pull/224

### Fixed

- Handle the number `0` in `*_list` functions https://github.com/thoughtbot/ex_machina/commit/012e957e7ab1e22eca18b62e8f3fcc2a98a7f286

### Improved

- Miscellaneous documentation improvements.

[2.1.0]: https://github.com/thoughtbot/ex_machina/compare/v2.0.0...v2.1.0

## [2.0.0]

### Added

- Cast all values before insert ([#149])

  For example, this means that if you have `field :equity, :decimal` in your
  schema, you can set the value to `0` in your factory and it will automatically
  cast the value to a Decimal.

- Add `string_params_for`, which is useful for controller specs. ([#168])
- Add `Sequence.reset/0` for resetting sequences between tests. ([#151])

### Changed

- `params_*` functions now drop fields with `nil` values ([#148])
- Don't delete `has_many`s from `params_*` functions ([#174])

### Fixed

- Fix an issue where values on embedded associations would not be cast ([#200])
- Only drop autogenerated ids ([#147])
- Fix an issue where setting an association to `nil` would break `insert` ([#193])
- Fix an issue where unbuild has_many through associations were not removed in
  `params_*` functions ([#192])

[2.0.0]: https://github.com/thoughtbot/ex_machina/compare/v1.0.2...v2.0.0
[#200]: https://github.com/thoughtbot/ex_machina/pull/200
[#149]: https://github.com/thoughtbot/ex_machina/pull/149
[#151]: https://github.com/thoughtbot/ex_machina/pull/151
[#148]: https://github.com/thoughtbot/ex_machina/pull/148
[#147]: https://github.com/thoughtbot/ex_machina/pull/147
[#168]: https://github.com/thoughtbot/ex_machina/pull/168
[#174]: https://github.com/thoughtbot/ex_machina/pull/174
[#193]: https://github.com/thoughtbot/ex_machina/pull/193
[#192]: https://github.com/thoughtbot/ex_machina/pull/192

## [1.0.2]

Minor documentation fixes

[1.0.2]: https://github.com/thoughtbot/ex_machina/compare/v1.0.1...v1.0.2

## [1.0.1]

Small change to the error generated when a factory definition is not found ([#142])

[1.0.1]: https://github.com/thoughtbot/ex_machina/compare/v1.0.0...v1.0.1
[#142]: https://github.com/thoughtbot/ex_machina/pull/142

## [1.0.0]

A lot has changed but we tried to make upgrading as simple as possible.

**To upgrade:** In `mix.exs` change the version to `"~> 1.0"` and run `mix
deps.get`. Once you've updated, run `mix test` and ExMachina will raise errors
that show you what needs to change to work with 1.0.0.

### Fixed

- Fix compilation issues under OTP 19 ([#138])
- Raise helpful error when trying to insert twice ([#128])

### Added

- Add `Sequence.next/1` for quickly creating sequences. Example:
  `sequence("username")` will generate `"username1"`, then `"username2"` ([#84])
- Raise if passing invalid keys to structs ([#99])
- Add `params_with_assocs` ([#124])

### Changed

- Rename `fields_for` to `params_for` ([#98])
- If using ExMachina with Ecto, use `insert`, `insert_list` and `insert_pair`
  instead of `create_*`
- Instead of defining a custom `save_record`, you can now implement an
  `ExMachina.Strategy`. See the documentation on hex.pm for more info ([#102])
- Define factory as `user_factory` instead of `factory(:user)` ([#110]). See PR
  and related issue for details on why this was changed.
- `params_for` no longer returns the primary key ([#123])

[1.0.0]: https://github.com/thoughtbot/ex_machina/compare/v0.6.1...v1.0.0
[#138]: https://github.com/thoughtbot/ex_machina/pull/138
[#128]: https://github.com/thoughtbot/ex_machina/pull/128
[#84]: https://github.com/thoughtbot/ex_machina/pull/84
[#99]: https://github.com/thoughtbot/ex_machina/pull/99
[#124]: https://github.com/thoughtbot/ex_machina/pull/124
[#98]: https://github.com/thoughtbot/ex_machina/pull/98
[#102]: https://github.com/thoughtbot/ex_machina/pull/102
[#110]: https://github.com/thoughtbot/ex_machina/pull/110
[#123]: https://github.com/thoughtbot/ex_machina/pull/123

## [0.6.1]

Removes warnings as reported by
https://github.com/thoughtbot/ex_machina/issues/70. We recommend updating if you
are using Ecto 1.1. There are no backward incompatible changes and no new
features.

[0.6.1]: https://github.com/thoughtbot/ex_machina/compare/v0.6.0...v0.6.1

## [0.6.0]

You can continue using ExMachina 0.5.0 if you are not ready for Ecto 1.1 yet.
There are no additional new features in this release.

- Updated to use Ecto 1.1
- Require Ecto 1.1

There are still some warnings that we need to fix for Ecto 1.1, but this release
at least fixes the error that was caused when upgrading to Ecto 1.1.

[0.6.0]: https://github.com/thoughtbot/ex_machina/compare/v0.5.0...v0.6.0

## [0.5.0]

### Changed

- Factories were simplified so that `attrs` is no longer required. See [70a0481] and [issue #56]
- ExMachina.Ecto.assoc/3 was removed. You can now use build(:factory) instead. See discussion in [issue #56]

### Fixed
- Use association id as defined on the schema [7c67047]

[issue #56]:https://github.com/thoughtbot/ex_machina/issues/56
[70a0481]: https://github.com/thoughtbot/ex_machina/commit/70a04814aacc33b3c727e133f4bd6b03a8217731
[7c67047]:https://github.com/thoughtbot/ex_machina/commit/7c6704706cffa7285a608049a1b1f10784790fdd
[0.5.0]: https://github.com/thoughtbot/ex_machina/compare/v0.4.0...v0.5.0

## [0.4.0]

### Added

- Add support for `has_many` and `has_one` Ecto associations. See [1ff4198].

### Changed

- Factories must now be defined with functions. See [59b7d23]

[1ff4198]: https://github.com/thoughtbot/ex_machina/commit/1ff4198488caa8225563ec2d4262a6f42d7d29be
[59b7d23]: https://github.com/thoughtbot/ex_machina/commit/59b7d23522d8ef4a3ae209f856b4d3c159de376e
[0.4.0]: https://github.com/thoughtbot/ex_machina/compare/v0.3.0...v0.4.0

## [0.3.0]

### Added

- Add `build_list` and `build_pair`. See [8f332ce].
- Add a `create` method that takes a map. This allows you to chain functions
like: `build(:foo) |> make_admin |> create`. See [59cbef5].

[8f332ce]: https://github.com/thoughtbot/ex_machina/commit/8f332ce0499f4e81f9dbb653fef3a6bc1e697cb6
[59cbef5]: https://github.com/thoughtbot/ex_machina/commit/59cbef569d7740d2958653fe177790b0cb506ff6

### Changed

- Factories must now be defined with a macro. See [03c41f6]
- `belongs_to` associations are now built instead of created. See [b518285].

[b518285]: https://github.com/thoughtbot/ex_machina/commit/b518285fa144459c36848bda5e72498914c19cdd
[03c41f6]: https://github.com/thoughtbot/ex_machina/commit/03c41f64470423a168f91d40edcd91eb242c3c61
[0.3.0]: https://github.com/thoughtbot/ex_machina/compare/v0.2.0...v0.3.0

## [0.2.0]

### Changed

- Ecto functionality was extracted to `ExMachina.Ecto`. See [270c19b].

[270c19b]: https://github.com/thoughtbot/ex_machina/commit/270c19bbb805b7c62365612419410990f28c8baf
[0.2.0]: https://github.com/thoughtbot/ex_machina/compare/v0.1.0...v0.2.0
