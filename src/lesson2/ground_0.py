def nuke(n):

       a = []

       for i in range(n):

           if n > 1:

               a.append(nuke(n-1))

           else:

               a.append(0)

       return a

nuke(12)