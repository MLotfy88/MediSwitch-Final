
with open('/home/adminlotfy/project/External_source/TTD-IDRBLab/P1-05-Drug_disease.txt', 'rb') as f:
    for i, line in enumerate(f):
        if line.startswith(b'INDICATI'):
            print(f"Line {i}: {line}")
            print(f"Hex: {line.hex()}")
            
            decoded = line.decode('utf-8').strip()
            parts = decoded.split('\t')
            print(f"Split by tab: {parts}")
            
            # محاولة طريقتي
            data_skip_9 = decoded[9:].split('\t')
            print(f"Skip 9 chars: {data_skip_9}")
            
            # محاولة طريقتي السابقة
            data_skip_8 = decoded[8:].split('\t')
            print(f"Skip 8 chars: {data_skip_8}")
            
            break
