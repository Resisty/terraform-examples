import boto3
import base64

kms = boto3.client('kms', region_name='${region_name}')

def kms_decrypt(ciphertext):
    return kms.decrypt(CiphertextBlob=base64.b64decode(ciphertext)).get('Plaintext').decode('utf-8')

def kms_encrypt(plaintext, key):
    return base64.b64encode(kms.encrypt(KeyId=key,Plaintext=plaintext).get('CiphertextBlob'))

class FilterModule(object):
    def filters(self):
        return { 'kms_encrypt': kms_encrypt, 'kms_decrypt': kms_decrypt }
