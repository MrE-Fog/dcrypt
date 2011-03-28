dcrypt = require '../dcrypt'
sys = require 'sys'
crypto = require 'crypto'
assert = require 'assert'
fs = require 'fs'

console.log "Entering test.coffee"
console.log dcrypt

testRandBytes = (test) ->
  size = 16
  test.expect 3
  r = dcrypt.random.randomBytes size 
  test.equal "object", typeof r
  test.notEqual r, []
  test.equal size, r.length
  test.done()

testKeyPairs = (test) ->
  test.expect(8)
  test.notDeepEqual(dcrypt.keypair.newRSA(), {})
  test.notDeepEqual(dcrypt.keypair.newRSA(1024))
  test.notDeepEqual(dcrypt.keypair.newRSA(2048, 3), {})
  test.throws(dcrypt.keypair.newRSA(2048, 3))

  test.notDeepEqual(dcrypt.keypair.newECDSA(), {})
  test.notDeepEqual(dcrypt.keypair.newECDSA('prime192v1'), {})
  test.notDeepEqual(dcrypt.keypair.newECDSA('prime256v1'), {})
  #for some reason nodeunit wont treat test.throws as working with newECDSA with a bad curve
  try
    dcrypt.keypair.newECDSA('1234')
    test.throws(1)
  catch error
    test.ok true
  test.done()

testHash = (test)  ->
  h = dcrypt.hash.createHash("SHA256")
  h.update('test')
  hash1= h.digest(encoding='hex')

  x = crypto.createHash("SHA256")
  x.update('test')
  hash2 = x.digest(encoding='hex')

  test.deepEqual hash1, hash2
  test.done()

testSign = (test) ->
  algo = 'SHA256'
  message = 'this is a test message'

  keys = dcrypt.keypair.newRSA(1024)
  pub = keys.pem_pub.toString()
  priv = keys.pem_priv.toString()

  nsigner = crypto.createSign algo
  nsigner.update message
  nsig = nsigner.sign priv, output_format='hex'

  signer = dcrypt.sign.createSign algo
  signer.update message
  sig = signer.sign priv, output_format='hex'
  test.deepEqual nsig, sig

  nverif = crypto.createVerify algo
  nverif.update message
  npass = nverif.verify(pub, nsig, signature_format='hex')

  dverif = dcrypt.verify.createVerify algo
  dverif.update message
  dpass = dverif.verify(pub, nsig, signature_format='hex')
  test.ok dpass

  dverif2 = dcrypt.verify.createVerify algo
  dverif2.update message
  dpass = dverif2.verify(pub, 'bad sig', signature_format='hex')
  test.ok !dpass

  keys = dcrypt.keypair.newECDSA()
  signer = dcrypt.sign.createSign "SHA1"
  signer.update message
  ecsig = signer.sign keys.pem_priv, output_format='hex'

  ecverif = dcrypt.verify.createVerify "SHA1"
  ecverif.update message
  ecpass = ecverif.verify(keys.pem_pub, ecsig, signature_format='hex') 
  test.ok ecpass

  test.notDeepEqual sig, ecsig
  test.done()

testCipher = (test) ->
  key = 'Test key here'
  message = 'This is the test message!'
  algo = 'aes-256-cbc'

  cipher = dcrypt.cipher.createCipher(algo, key)
  ct = cipher.update(message, 'utf8', 'hex')
  ct += cipher.final('hex')

  test.notDeepEqual(message, ct)

  ndecipher = crypto.createDecipher(algo, key)
  mt = ndecipher.update(ct, 'hex', 'utf8')
  mt += ndecipher.final('utf8')

  test.deepEqual(mt, message)

  #reuse
  cipher.init(algo, key)
  ct2 = cipher.update(message, 'utf8', 'hex')
  ct2 += cipher.final('hex')

  decipher = dcrypt.decipher.createDecipher(algo, key)
  clear = decipher.update(ct2, 'hex', 'utf8')
  clear += decipher.final('utf8')

  test.deepEqual(clear, message)

  test.deepEqual(ct, ct2)
  test.done()

testRSAEncrypt = (test) ->
  key = dcrypt.keypair.newRSA()
  pub = key.pem_pub
  priv = key.pem_priv
  message = 'test message'

  enc = dcrypt.rsa.encrypt(pub, message, 'RSA_PKCS1_PADDING', 'hex')
  clear_msg = dcrypt.rsa.decrypt(priv, enc, 'RSA_PKCS1_PADDING', 'hex')
  test.deepEqual clear_msg, message
  test.done()

exports.testKeyPairs = testKeyPairs
exports.testRandomBytes = testRandBytes
exports.testHash = testHash
exports.testSign = testSign
exports.testCipher = testCipher
exports.testRSAEncrypt = testRSAEncrypt
