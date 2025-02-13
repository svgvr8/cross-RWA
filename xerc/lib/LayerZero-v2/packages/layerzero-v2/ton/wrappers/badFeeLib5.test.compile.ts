import { CompilerConfig } from '@ton/blueprint'

export const compile: CompilerConfig = {
    lang: 'func',
    targets: ['src/protocol/msglibs/ultralightnode/uln/tests/badFeeLib/badFeeLib5.fc'],
}
