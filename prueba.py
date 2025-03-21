text = """
MVDILDASNSVSRLSLLGDGEEQDFKWKKPLELFAERKFVRICAPMVRYSKLPFRLLTRK
YGVDLAYTPMIVSNSFLCSLKARDSDFTTCNVDRPLIVQFAASNTEDFVRASQIVVPYAD
GVDLNCGCPQRWAQAEGYGACLLRKPEIVQDMIRQTKGAISSQDFTISIKIRIHHNIRET
VEFCRKMEHAGLSWLAVHGRTPEQRGEPVNNEAIQLIKSSVNIPVIANGDVKSLEGAKKI
HTETKANGIMAARGILSNPSMFAGYQSTPEECVKDWIYLALSTGTSFQCFHHHLTFMLQK
AMSRAEQTVFASLASTSSVLQFLKENFGISAPRIPVKS
"""

# remove \n
text = text.replace('\n', '')

offset = 32

# print(text[offset])
# offset += offset
# print(text[offset])
# offset += offset
# print(text[offset])
# offset += offset
# print(text[offset])

# remove the offset

new_text = text[offset:]
# print all the indexes where G is found
for i in range(len(new_text)):
    if new_text[i] == 'G':
        print(i)

