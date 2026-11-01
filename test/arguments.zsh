#!/usr/bin/env zsh
set -e

compdef() {}
source "${0:A:h:h}/ni.zsh"
unset NI_USE_SOCKET_FIREWALL NI_SOCKET_FIREWALL_BIN

ni-getPackageManager() {
  print -r -- "$testManager"
}

for executable in npm yarn pnpm bun deno vp aube npx bunx; do
  functions[$executable]='captured=("$0" "$@")'
done
executable='socket firewall'
functions[$executable]='captured=("$0" "$@")'

assert-arguments() {
  local -a expected=("$@")
  if (( ${#captured} != ${#expected} )); then
    print -ru2 -- "Expected (${#expected} arguments): ${(j: :)${(@q)expected}}"
    print -ru2 -- "Actual (${#captured} arguments): ${(j: :)${(@q)captured}}"
    return 1
  fi
  local index
  for (( index = 1; index <= ${#expected}; index++ )); do
    if [[ "${captured[index]}" != "${expected[index]}" ]]; then
      print -ru2 -- "Argument $index: expected ${(q)expected[index]}, got ${(q)captured[index]}"
      return 1
    fi
  done
}

for testManager in npm yarn yarn-berry pnpm bun deno vite-plus aube; do
  executable=$testManager
  case $testManager in
    yarn-berry) executable=yarn ;;
    vite-plus) executable=vp ;;
  esac
  prefix=("$executable" run)
  [[ $testManager != npm ]] || prefix+=(--)

  ni run arg\ 1 >/dev/null
  assert-arguments "${prefix[@]}" 'arg 1'

  arguments=('arg 1' '' 'two  spaces' $'tab\there' $'line\nbreak' '"quoted"' "it's literal" '\' '*' '$HOME' '$(exit 1)' '; exit 1')
  ni run main "${arguments[@]}" >/dev/null
  assert-arguments "${prefix[@]}" main "${arguments[@]}"

  ni test "${arguments[@]}" >/dev/null
  assert-arguments "${prefix[@]}" test "${arguments[@]}"

  ni-run "${arguments[@]}" >/dev/null
  assert-arguments "${prefix[@]}" "${arguments[@]}"

  case $testManager in
    npm) prefix=(npm install); developmentFlag=(--save-dev) ;;
    yarn*) prefix=(yarn add); developmentFlag=(--dev) ;;
    bun) prefix=(bun add); developmentFlag=(-d) ;;
    deno) prefix=(deno add --npm); developmentFlag=() ;;
    *) prefix=("$executable" add); developmentFlag=(-D) ;;
  esac
  ni add 'package name' --dev >/dev/null
  assert-arguments "${prefix[@]}" 'package name' "${developmentFlag[@]}"
  ni add 'package name' >/dev/null
  assert-arguments "${prefix[@]}" 'package name'
done

testManager=pnpm
ni exec command 'arg 1' '' >/dev/null
assert-arguments pnpm exec command 'arg 1' ''

testManager=yarn-berry
ni upgrade-interactive >/dev/null
assert-arguments yarn up --interactive '*'

export NI_USE_SOCKET_FIREWALL=1
export NI_SOCKET_FIREWALL_BIN='socket firewall'
testManager=pnpm
ni add 'package name' --dev >/dev/null
assert-arguments 'socket firewall' pnpm add 'package name' -D
ni run arg\ 1 >/dev/null
assert-arguments pnpm run 'arg 1'
testManager=npm
ni dlx command 'arg 1' '' >/dev/null
assert-arguments 'socket firewall' npx command 'arg 1' ''
testManager=bun
ni exec command 'arg 1' '' >/dev/null
assert-arguments 'socket firewall' bunx command 'arg 1' ''

print -r -- 'Argument tests passed'
