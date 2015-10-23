# Changelog

The noteworthy changes for each ExMachina version are included here. For a
complete changelog, see the git history for each version via the version links.

## [0.4.0] - In progress

### Added

- Add support for `has_many` and `has_one` Ecto associations. See [1ff4198].

### Changed

- Factories must now be defined with functions. See [59b7d23]

[1ff4198]: https://github.com/thoughtbot/ex_machina/commit/1ff4198488caa8225563ec2d4262a6f42d7d29be
[59b7d23]: https://github.com/thoughtbot/ex_machina/commit/59b7d23522d8ef4a3ae209f856b4d3c159de376e
[0.4.0]: https://github.com/thoughtbot/ex_machina/compare/v0.3.0...v0.4.0

## [0.3.0] - October 7, 2015

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

## [0.2.0] - September 17, 2015

### Changed

- Ecto functionality was extracted to `ExMachina.Ecto`. See [270c19b].

[270c19b]: https://github.com/thoughtbot/ex_machina/commit/270c19bbb805b7c62365612419410990f28c8baf
[0.2.0]: https://github.com/thoughtbot/ex_machina/compare/v0.1.0...v0.2.0
