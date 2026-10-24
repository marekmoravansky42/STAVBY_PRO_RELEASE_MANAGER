# FIX364 – test literal closure

FIX363 production/historical syntax repairs were accepted by analyzer; the only new syntax failure was inside FIX363's own source-text assertion with nested quote escaping. FIX364 removes that fragile assertion style and uses simple durable contract checks. Production FINAL logic is unchanged.
