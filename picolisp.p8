pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
function cons(e, l)
  return {e, l}
end
function isempty(l)
  if l == nil then
    return true
  elseif type(l) == "table" then
    return false
  else
    assert(
     false,
     "expected a list: " ..
      type(l) ..
      " : " ..
      tostring(l))
  end
end
assert(isempty(nil))
assert( not isempty(cons(1, nil)))
assert(not isempty(cons(nil, nil)))
function first(l)
  if isempty(l) then
    return nil
  else
    return l[1]
  end
end
assert(first(nil) == nil)
assert(first(cons(1, nil)) == 1)
function rest(l)
  if isempty(l) then
    return nil
  else
    return l[2]
  end
end
assert(rest(cons(1,nil))==nil)
assert(
  first(
    rest(
      cons(1,
        cons(2, nil)))) == 2)
function nth(n, l)
  if l == nil then
    return nil
  elseif n > 0 then
    return nth(n-1, rest(l))
  else
    return first(l)
  end
end
function len(l)
  if l == nil then
    return 0
  else
    return 1 + len(rest(l))
  end
end
function pair(a, b)
  return cons(a, cons(b))
end
function tripple(a,b,c)
  return cons(a, pair(b,c))
end
function str2cons(str)
  local t = split(str, "", false)
  local l = nil
  for i=count(t),1,-1 do
    l = cons(t[i], l)
  end
  return l
end
prelude = {}
function def(n, f, env)
  if env == nil then
    env = prelude
  end
  env[n] = f
  return f
end
function getval(name, env)
  assert(name ~= nil)
  assert(type(name)=="string")
  local v = env[name]
  return v
end
function native_wrapper(nargs, native)
  assert(nargs == 2)
  local args = cons("a", cons("b"))
  local impl = cons(native, args)
  local fn = cons("fn", cons(args, cons(impl)))
  return fn
end
arg1 = cons("a")
arg2 = cons("b", cons("a"))
function defnative(name, binds, native)
  return def(name, tripple("native", binds, native), prelude)
end
args1 = cons("a")
args2 = pair("a", "b")
args3 = tripple("a", "b", "c")
defnative("def", args2, def)
defnative("cons", args2, cons)
defnative("len", args1, len)
defnative("first", args1, first)
defnative("nth", args2, nth)
defnative("pair", args2, pair)
defnative("tripple", args3, tripple)
def("$t", true)
def("nil", nil)
defnative("empty?", args1, isempty)
assert(getval("$t", prelude))
function defzip(
 binds, vals, env)
  assert(env ~= nil)
  if binds == nil and vals == nil then
    return env
  elseif binds == nil or vals == nil then
    return error("variadic mismatch", binds or vals)
  else
    def(
     first(binds),
     first(vals),
     env)
    return defzip(
     rest(binds),
     rest(vals),
     env)
   end
end
assert(
 defzip(
  cons("a"),
  cons("b"),
  {})["a"]
   == "b")
function second(l)
  return first(rest(l))
end
assert(second(nil) == nil)
assert(second(
  cons(1, nil)) == nil)
assert(second(
  cons(1, cons(2, nil))) == 2)
assert(second(
  cons(1, cons(2, cons(3, nil))))
  == 2)
defnative("second", arg1, second)
defnative("rest", arg1, rest)
function third(l)
  return first(rest(rest(l)))
end
function cons2str(l,s)
  if isempty(l) then
    return s
  else
    local p = s .. first(l)
    local r = rest(l)
    return cons2str(r, p)
  end
end
assert(
  cons2str(
    str2cons("abc"),
  "zzz")
  == "zzzabc")
defnative("str2cons", args1, str2cons)
defnative("cons2str", args1, cons2str)
-->8
function error(msg, form)
  return cons("error",
    cons(msg,
      cons(form)))
end
function iserror(form)
  return bool(islist(form) and first(form) == "error")
end
function check_numbers(op)
  function checked(a,b)
    if type(a) ~= "number" then
      return error("not int", a)
    elseif type(b) ~= "number" then
      return error("not int", b)
    end
    return op(a,b)
  end
  return checked
end
function bool(b)
  if b == false or b == nil then
    return nil
  else
    return "$t"
  end
end
function add_op(a,b)
  return a+b;
end
function sub_op(a,b)
  return a-b;
end
function mul_op(a,b)
  return a*b;
end
function div_op(a,b)
  return a/b;
end
function mod_op(a,b)
  return a%b;
end
function gt_op(a,b)
  return bool(a>b)
end
function lt_op(a,b)
  return bool(a<b)
end
defnative("+", args2,  check_numbers(add_op))
defnative("-", args2,  check_numbers(sub_op))
defnative("*", args2,  check_numbers(mul_op))
defnative("/", args2,  check_numbers(div_op))
defnative("%", args2,  check_numbers(mod_op))
defnative(">", args2,  check_numbers(gt_op))
defnative("<", args2,  check_numbers(lt_op))
function eq_op(a,b)
  return bool(a==b)
end
function equals_op(a,b)
  if type(a) ~= type(b) then
    return nil
  elseif type(a) == "table" then
    if isempty(a) and isempty(b) then
      return "bothempty" -- true
    elseif isempty(a) or isempty(b) then
      return nil
    elseif equals(first(a), first(b)) then
      return equals(rest(a), rest(b))
    else
      return nil
    end
  else
    return eq_op(a,b)
  end
end
defnative("equals_op", args2, equals_op)
function not_op(a)
  if a == nil then
    return true
  else
    return nil
  end
end
defnative("!", args1, not_op)
function native(e)
  return type(e) == "function"
end
assert(not native(1))
assert(native(cons))
function islist(e)
  return bool(e == nil or type(e) == "table")
end
assert(not islist(1))
assert(islist(nil))
assert(islist(cons(1,nil)))
defnative("list?", args1, islist)
function isnum(e)
  return bool(type(e) == "number")
end
assert(isnum(1))
assert(not isnum(nil))
assert(not isnum("a"))
defnative("num?", args1, isnum)
function issym(e)
  return bool(type(e) == "string")
end
assert(not issym(1))
assert(issym("a"))
assert(not issym(nil))
assert(issym("abc"))
defnative("sym?", args1, issym)
--TODO isalpha not in repl
--TODO isalpha has weird semantics and throws.
function isalpha(c)
  assert(type(c) == "string"
      or c == nil,
    type(c))
  if c == nil then
    return false
  else
    return type(c) == "string" and
      c~= "(" and
      c~= ")" and
      c~= " "
  end
end
-- TODO remove == true or == false
assert(isalpha(nil) == false)
assert(isalpha("a") == true)
assert(isalpha("z") == true)
assert(isalpha("(") == false)
assert(isalpha(" ") == false)
assert(isalpha("2") == true)
assert(isalpha("+") == true)
function iswhite(c)
  if c == nil then
    return false
  else
    return c == " "
  end
end
-- TODO remove == true or == false
assert(iswhite(nil) == false)
assert(iswhite("a") == false)
assert(iswhite(" ") == true)
function isbool(f)
  if type(f) == "boolean" then
    return true
  else
    return false
  end
end
-->8
function decons(l)
  local t = {}
  local i = 1
  while not isempty(l) do
    t[i] = l[1]
    l = l[2]
    i = i + 1
  end
  return t
end
assert(count(decons(nil)) == 0)
assert(count(
  decons(
    cons(1, nil))) == 1)
assert(count(
  decons(
    cons(1,
      cons(2, nil)))) == 2)
defnative("decons", args1, decons)
function stringseq(seq)
  if seq == nil then
    return ""
  else
    if type(seq) ~= "table" then
      return error(
       "unexpected",
       tostring(seq))
    end
    local fst =
     string(
      first(
       seq))
    if rest(seq) then
      local rst =
       stringseq(
        rest(
         seq))
      return fst .. " " .. rst
    else
      return fst
    end
  end
end
function string(form)
  if isnum(form) then
    return tostring(form)
  elseif issym(form) then
    return form
  elseif native(form) then
    return sub(tostring(form), 10)
  elseif isbool(form) then
    if form then
      return "$t"
    else
      assert(
       false,
       "got false, not nil")
    end
  elseif islist(form) then
    local toks = stringseq(form)
    return "(" .. toks .. ")"
  else
    assert(false, type(form))
  end
end
assert(string(add_op) == sub(tostring(add_op), 10))
assert(string(1) == "1")
assert(string("a") == "a")
assert(string(nil) == "()")
assert(
  string(cons(1, nil)) == "(1)")
assert(
  string(
    cons(1, 
      cons(2, nil))) == "(1 2)")


-->8
function evnative(fn, args, env)
  local binds = second(fn)
  local forms = third(fn)
  local copy = ns(env)
  local envf = defzip(binds, args, copy)
  if iserror(envf) then
    return envf
  end
  args = decons(args)
  return forms(unpack(args))
end
-- ((fn (a b) (+ a b)) 1 2)
--fn                 args  env
--(fn (a b) (+ a b)) (1 2) (.)
function evfn(fn, args, env)
  local binds = second(fn)
  local forms = third(fn)--rest?
  assert(env ~= nil)
  local copy = ns(env)
  assert(copy ~= nil)
  local envf = defzip(
   binds, args, copy)
  assert(envf ~= nil)
  if iserror(envf) then
    return envf
  end
  return eval(forms, envf)
end
function evlist(l, env)
  if isempty(l) then
    return nil
  else
    local fst = eval(
     first(l), env)
    local rst = evlist(
     rest(l), env)
    return cons(fst, rst)
  end
end
-- symbol (1 2)
-- native (1 2)
-- (fn (a b) (+ a b) (1 2) (.)
function apply(fn, args, env)
  if issym(fn) then
    return apply(
      eval(fn, env),
      args,
      env)
  elseif first(fn) == "native" then
    args = evlist(args, env)
    return evnative(fn, args, env)
  elseif first(fn) == "fn" then
    assert(env ~= nil)
    args = evlist(args, env)
    return evfn(fn, args, env)
  elseif first(fn) == "macro" then
    assert(env ~= nil)
    local exp = evfn(fn, args, env)
    return eval(exp, env)
  elseif first(fn) == "error" then
    return fn
  else
    return error(
     "not a fn",
     string(fn))
  end
end
defnative("apply", args3, apply)
function evcond(f, env)
  assert(f ~= nil,
   "cond fallthrough")
  local tst = first(f)
  local thn = second(f)
  local rslt = eval(tst, env)
  if rslt ~= nil then
    return eval(thn, env)
  else
    return evcond(
     rest(
      rest(f)),
     env)
  end
end
function deflst(vs, env)
  if vs == nil then
    return env
  else
    local n = first(vs)
    local v = second(vs)
    local vf= eval(v, env)
    def(n, vf, env)
    return deflst(
     rest(rest(vs)), env)
  end
end
function ns(env)
  local new = {}
  for k,v in pairs(env) do
    new[k] = v
  end
  return new
end
defnative("ns", args1, ns)
function evlet(f, env)
  local vars = first(f)
  local envf = deflst(
   vars,
   ns(env))
  --todo new env?
  return eval(second(f), envf)
end
function eval(form, env)
  if islist(form) then
    local fst = first(form)
    local rst = rest(form)
    if fst == nil then
      return nil
    elseif fst == "quote" then
      return first(rst)
    elseif fst == "list" then
      return evlist(first(rst), env)
    elseif fst == "def" then
      return def(
       first(rst), eval(second(rst), prelude))
    elseif fst == "cond" then
      return evcond(rst, env)
    elseif fst == "let" then
      return evlet(rst, env)
    elseif fst == "fn" then
      return form
    elseif fst == "macro" then
      return form
    elseif fst == "error" then
      return form
    else -- must be an call
      --fst (fn (a b) (+ a b))
      --rst (1 2)
      return apply(fst, rst, env)
    end
  else -- not a list
    -- TODO use isbool
    if isbool(form) then
      return form
    elseif isnum(form) then
      return form
    elseif native(form) then
      return form
    else
      return getval(form, env)
    end
  end
end
assert(apply(
  tripple("native", args2, add_op),
  cons(1, cons(2, nil))) == 3)
assert(eval(1) == 1)
assert(eval(nil) == nil)
defnative("eval", args2, eval)
-->8
function takepred(p,r,l)
  local chars = 0
  local acc = nil
  local out = nil
  local c = first(l)
  while p(c) do
    chars += 1
    acc = r(acc, c)
    l = rest(l)
    c = first(l)
    out = cons(acc)
  end
  return tripple(
  chars,
  out,
  l)
end
function buildstr(a,c)
  if a == nil then
    a = ""
  end
  return a..c
end
assert(buildstr(nil,"a") == "a")
assert(buildstr("a","b") == "ab")
function takesym(l)
  return takepred(
      isalpha,
      buildstr,
      l)
end
assert(
  string(
    takesym(
      str2cons("")))
  == "(0 () ())")
assert(
  string(
    takesym(
      str2cons("abc 123")))
  == "(3 (abc) (  1 2 3))")
function buildnum(a, c)
  if a == nil then
    a = 0
  end
  return 10 * a + (c-"0")
end
function isnumchar(c)
  return type(c) == "string" and
    c >= "0" and c <= "9"
end
function takenum(l)
  return takepred(
      isnumchar,
      buildnum,
      l)
end
assert(
  string(
    takenum(
      str2cons("")))
  == "(0 () ())")
assert(
  string(
    takenum(
      str2cons("123 abc")))
  == "(3 (123) (  a b c))")
function takewhite(l)
  return takepred(
      iswhite,
      buildstr,
      l)
end
assert(
  string(
    takewhite(
      str2cons("")))
  == "(0 () ())")
assert(
  string(
    takewhite(
      str2cons("  123")))
  == "(2 (  ) (1 2 3))")
function taketoks(l)
  if l == nil then
    return tripple(0, nil, nil)
  end
  local head = read(l)
  if second(head) == nil then
    return tripple(
     first(head),
     nil,
     third(head))
  end
  local tail = taketoks(
   third(head))
  return tripple(
   first(head) + first(tail),
   cons(
    first(second(head)),
    second(tail)),
   third(tail))
end
function takelist(l)
  if first(l) ~= "(" then
    return tripple(0, nil, l)
  end
  l = rest(l)
  local chars = 1
  local toks = taketoks(l)
  chars += first(toks)
  local lst = second(toks)
  l = third(toks)
  if first(l) ~= ")" then
    return tripple(
     chars,
     nil,
     l)
  end
  l = rest(l)
  chars += 1
  return tripple(
   chars,
   cons(lst),
   l)
end
function readmacro(c,f,l)
  if first(l) == c then
    l = rest(l)
    local nxt = read(l)
    local nxt_chars = first(nxt)
    local nxt_tok = second(nxt)
    local nxt_rem = third(nxt)
    if nxt_tok then
      return tripple(
       nxt_chars+1,
       cons(
        cons(
         f,
         nxt_tok)),
       nxt_rem)
     else
       return tripple(
        nxt_chars+1,
        nil,
        nxt_rem)
      end
  else -- not macro
    return tripple(0,nil,l)
  end
end
function quoter(l)
  return readmacro("'", "quote", l)
end
function lister(l)
  return readmacro("`", "list", l)
end
parsers = {
  quoter,
  lister,
  takenum,
  takesym,
  takelist}
function read(l)
  local chars = 0
  if l == nil then
    return tripple(0, cons(nil), nil)
  end
  local white = takewhite(l)
  chars += first(white)
  l = third(white)
  for p in all(parsers) do
    --todo take the longest parse
    local o = p(l)
    local c = first(o)
    local mv = second(o)
    local r = third(o)
    chars+=c
    local white = takewhite(r)
    chars+=first(white)
    r2 = third(white)
    if mv ~= nil then
     return tripple(
      chars,mv,r2)
    end
  end
  return tripple(0, nil, l)
end
function parse(s)
  local chars = str2cons(s)
  local out = read(chars)
  if second(out) == nil then
    return error("failed to parse", s)
  end
  local expr = first(second(out))
  local rem = third(out)
  if rem ~= nil then
    return error("remaining", rem)
  else
    return cons("success", expr)
  end
end
assert(
  string(
    takelist(
      str2cons(
        "()"))) 
  == "(2 (()) ())")
assert(
  string(
    takelist(
      str2cons(
        "( )"))) 
  == "(2 (()) ())")
-- assert(
--   string(parse(" "))
--   == "()") --"(() ())")
assert(
  string(rest(parse("123")))
  == "123") --"(123 ())")
assert(
  string(rest(parse("abc")))
  == "abc")
assert(
  string(rest(parse("(123a)")))
  == "(123 a)") --todo wrong
assert(
  string(rest(parse("(abc1)")))
  == "(abc1)")
assert(
  string(rest(parse("(abc)")))
  == "(abc)")
assert(
  string(
   read(
    str2cons(" ( abc 123 ) ")))
  == "(13 ((abc 123)) ())")

function inject(expr)
  eval(
   rest(
    parse(expr)), prelude)
end
inject("(def defn (macro (name args impl) `('def name `('fn args impl))))")
inject("(defn inc (x) (+ x 1))")
inject("(def defmacro (macro (name args impl) `('def name `('macro args impl))))")
inject("(defmacro if (tst hpy sad) `('cond tst  hpy $t sad))")
inject("(defmacro and (a b) `('if a `('if b '$t 'nil) 'nil))")
inject("(defmacro or (a b) `('if a '$t `('if b '$t 'nil)))")
inject("(defn reverse (l o) (if l (reverse (rest l) (cons (first l) o)) o))")
inject("(defn reduce (f a c) (if c (reduce f (f (first c) a) (rest c)) a))")
inject("(defn map (f c) (if c (cons (f (first c)) (map f (rest c))) nil))")
inject("(defn filter (p c) (if c (if (p (first c)) (cons (first c) (filter p (rest c))) (filter p (rest c))) nil))")
inject("(defn even? (x) (= 0 (% x 2)))")
inject("(defn every? (p c) (if c (if (p (first c)) (every? p (rest c)) nil) $t))")
inject("(defn = (a b) (equals_op a b))")
inject("(defn >= (a b) (or (> a b) (= a b)))")
inject("(defn <= (a b) (or (< a b) (= a b)))")

def("pass", 0, prelude)
def("fail", 0, prelude)
def("tests", cons("$t"), prelude)
tstmacro = "(def tst (macro (case) `(case)))"
eval(
 rest(
  parse(tstmacro)), prelude)

-->8
function update_line(deltal, l)
  if l == nil then
    l = getval("line", prelude)
  end
  l += deltal
  l = l % 16
  def("line", l)
end
function grect(h,v,x,y,c)
  rectfill(h,v,h+x-1,v+y-1,c)
end --grect(.)
function clear_line(l)
  grect(0,l*8,128,5)
end
function print_line(t,color)
  local l = getval("line", prelude)
  local dl = 0
  clear_line(l+dl)
  while #t > 0 do
    local cur = sub(t,0,30)
    t = sub(t, 30+1)
    clear_line(l+dl)
    print(cur,0,(l+dl)*8,color)
    dl+=1
  end
  return dl
end
function clear()
  for i=1,16 do
    clear_line(i)
  end
  update_line(0,0)
end
defnative("clear", nil, clear)
def("history", nil)
def("hindex", -1)
function update_hindex(delta)
  local cnt = len(getval("history", prelude))
  local hindex = getval("hindex", prelude)
  hindex += delta
  local new = max(min(cnt-1, hindex), -1)
  def("hindex", new)
end
function get_history()
  local index = getval("hindex", prelude)
  if index < 0 then
    return ""
  end
  return string(nth(index, getval("history", prelude)))
end
function remove(s, pos)
  pos = pos + 1
  local prefix = sub(s, 0, max(0, pos - 1))
  local postfix = sub(s, pos+1, #s)
  return prefix .. postfix
end
function replace(s, pos, c)
  pos = pos + 1
  local prefix = sub(s, 0, max(0, pos - 1))
  local postfix = sub(s, pos+1, #s)
  return prefix .. c .. postfix
end
function insert(s, pos, c)
  pos = pos + 1
  local prefix = sub(s, 0, max(0, pos - 1))
  local postfix = sub(s, pos, #s)
  return prefix .. c .. postfix
end
blink_frame = 0
show_cursor = true
cursor_width = 1
cursor_fn = insert
function draw_cursor(p, color)
  blink_frame += 1
  if blink_frame % 20 == 0 then
    show_cursor = not show_cursor
  end
  if not show_cursor then
    return
  end
  local l = getval("line", prelude)
  while p > 30 do
    p -= 30
    l+=1
  end
  grect(p*4,l*8,cursor_width,5,color)
end
function repl()
  def("done", nil)
  ins = "pico8lisp repl"
  cls()
  print(ins,0,0,5)
  poke(24365,1) -- mouse+key kit
  t=""
  p=0
  def("column", 0)
  update_line(0,1)
  repeat
    local t_lines = print_line(t,6)
    draw_cursor(p, 8)
    flip()
    draw_cursor(p, 0) -- erase cursor
    poke(0x5f30,1) -- disable pause
    if(btnp(2)) then --up
      update_hindex(1)
      t = get_history()
      p = #t
    elseif(btnp(3)) then --down
      update_hindex(-1)
      t = get_history()
      p = #t
    elseif(btnp(1)) then --right
      p = min(p+1, #t)
    elseif(btnp(0)) then --left
      p = max(p-1, 0)
    end
    if stat(30)==true then
      c=stat(31)
      if c>=" " and c<="z" then
        t = cursor_fn(t, p, c)
        p += 1
        show_cursor = true
        blink_frame = 0
      elseif c=="\8" and #t > 0 and p > 0 then --delete
        t = remove(t, p-1)
        p -=1
      elseif c=="\131" and #t > 0 and p > 0 then --shift d
        t = remove(t, p)
      elseif c=="\13" then --return
        def("history", cons(t, getval("history", prelude)))
        def("hindex", -1)
        update_line(t_lines)
        p = 0
        local parsed =
          parse(t)
        local out = nil
        if first(parsed) == "error" then
          out = string(parsed)
        else
          out =
           string(
            eval(
             rest(parsed),
             prelude))
        end
        local out_lines = print_line(out, 9)
        update_line(out_lines) --advance cursor to next line
        t = ""
        p = #t
      elseif c == "\136" then -- cap I
        if cursor_fn == replace then
          cursor_fn=insert
          cursor_width = 1
        else
          cursor_fn=replace
          cursor_width = 3
        end
      end
    end
  until getval("done", prelude)
end --repl()
defnative("sfx", args1, sfx)
repl()

__gfx__
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00077000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__label__
50005550055055500550000055500000555055505550500000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000500500050505050000050500000505050005050500000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000500555055505050555055500000550055005550500000000000000000000000000000000000000000000000000000000000000000000000000000000000
50000500005050005050000050500000505050005000500000000000000000000000000000000000000000000000000000000000000000000000000000000000
55505550550050005500000055500000505055505000555000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000000000066000000060000000000666000006660060006000000000000000000000000000000000000000000000000000000000000000000000000000000
60000600000006000000600006000000006000000060006000600000000000000000000000000000000000000000000000000000000000000000000000000000
60006660000006000000600066600000666000000660006000600000000000000000000000000000000000000000000000000000000000000000000000000000
60000600000006000000600006000000600000000060006000600000000000000000000000000000000000000000000000000000000000000000000000000000
06000000000066600000060000000000666000006660060006000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06006600666066600000666000006600666006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60006060600060000000606000000600606000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60006060660066000000666000000600606000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60006060600060000000606000000600606000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06006660666060000000606000006660666006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99009990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09009090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09009090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09009090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99909990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06006600666066600000666066000660000006006660660000000600606006000000060000000000660000006060060006000600000000000000000000000000
60006060600060000000060060606000000060006000606000006000606000600000600006000000060000006060006000600060000000000000000000000000
60006060660066000000060060606000000060006600606000006000060000600000600066600000060000000600006000600060000000000000000000000000
60006060600060000000060060606000000060006000606000006000606000600000600006000000060000006060006000600060000000000000000000000000
06006660666060000000666060600660000006006000606000000600606006000000060000000000666000006060060006000600000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09009990990000000900909009000000090000000000990000009090090009000000000000000000000000000000000000000000000000000000000000000000
90009000909000009000909000900000900009000000090000009090009000900000000000000000000000000000000000000000000000000000000000000000
90009900909000009000090000900000900099900000090000000900009000900000000000000000000000000000000000000000000000000000000000000000
90009000909000009000909000900000900009000000090000009090009000900000000000000000000000000000000000000000000000000000000000000000
09009000909000000900909009000000090000000000999000009090090009000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06006660660006600000666006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000600606060000000606000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000600606060000000666000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60000600606060000000606000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06006660606006600000606006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99009900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99909990000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06000660066066006600000006000000000066000000660006000000660066606660000066606660000060606660600006000000000000000000000000000000
60006000606060606060000060006660000006000000060000600000060000600060000066000600000060606000600000600000000000000000000000000000
60006000606060606060000060000000000006000000060000600000060066600660000006600600000066606660666000600000000000000000000000000000
60006000606060606060000060006660000006000000060000600000060060000060000066600600000000600060606000600000000000000000000000000000
06000660660060606660000006000000000066600000666006000000666066606660000006000600000000606660666006000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99009990999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09000090009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09009990099000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09009000009000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99909990999000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06006000666066600000060066600000660006000000060066606600066000006660060006000000000000000000000000000000000000000000000000000000
60006000600006000000600060600000060000600000600006006060600000006060006000600000000000000000000000000000000000000000000000000000
60006000660006000000600066000000060000600000600006006060600000006600006000600000000000000000000000000000000000000000000000000000
60006000600006000000600060600000060000600000600006006060600000006060006000600000000000000000000000000000000000000000000000000000
06006660666006000000060066600000666006000000060066606060066000006660060006000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
99900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06006600666066600000660006606600666006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60006060600060000000606060606060600000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60006060660066000000606060606060660000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
60006060600060000000606060606060600000600000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
06006660666060000000666066006060666006000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
90000090000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
09000900000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00700000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
07000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
70000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
00000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000

__sfx__
00011f003c0503b070390603706036060350603406032060300502f0502d0502b040290502705025060240602306021060200601d0601c0701a07019070180701707016060150601306012060110600e0500c050
0001000001050030500605007050090500c0500e0500f05011050130501405016050180501a0501b0501d0501f050210502405026050280502a0502b0502e050300503205033050350503605038050390503b050
