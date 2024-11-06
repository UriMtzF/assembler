# assembler

Assembler in Dart with GUI in Flutter

## Assembler rules

All content is case-insensitive including variable names, labels but not String content.

If a part can be detected as unique the type must save the general type and its unique nature, i.e. `mov` is an instruction and must be saved as instruction and mov

### Segments

Each program can contain one of the following segments:

- stack: `.stack segment`
- data: `.data segment`
- code: `.code segment`

Each segment must start as stated before and should end with the `ends` keyword.

#### Stack segment

This should only contain one line such as:

```asm
dw 128 dup(0)
```

No other lines must be contained in the stack segment

#### Data segment

All variables must be defined here, each variable must contain the following parts in this order:

- Variable name: Must contain [a-z,A-Z,0-9,_] but cannot start with a number or be a reserved word.
- Size: [db,dw]
- Value or quantity: If it isn't a value it must add the following parts.
- dup(?): The default value that will be filled in all spaces, must be a valid value (number or String).

If other kind of data is included here, it is considered invalid.

#### Code segment

All the code must be included here.

### Instructions

Only the assigned instructions must be detected, other instructions must be showed as `Symbol`.

### Registers

All available registers must be detected.

### Numbers

Decimal, binary and hexadecimal numbers must be detected as number and its type.

#### Decimal numbers

The decimal numbers are written naturally, the only restriction is, the number must be at most 5 digits long (16 bits) or 3 digits long (8 bits).

#### Binary numbers

The binary number must include only 0s and 1s, ending with a `b`, the size must be either 8 or 16 digits long.

#### Hexadecimal numbers

The hex numbers are written in two ways, either of them must be 2 or 4 digits long and only include values between 0-F.

- Can be started with `0x` and followed by the number.
- Can be started with `0`, followed by the number and ended with an `h`.

### Labels

All labels must follow the same restrictions as the variables and must end with a `:`, even if `:` its a separator, the label cannot be separated from the colon.

### Pseudoinstructions

All pseudoinstructions must be detected as such and cannot be separated in word as all of them are full tokens.
