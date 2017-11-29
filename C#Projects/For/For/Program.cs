using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.DirectoryServices;
using System.DirectoryServices.AccountManagement;

namespace For
{
    class Program
    {
        static void Main(string[] args)
        {
            var parentEntry = new DirectoryEntry("LDAP://" + Environment.UserDomainName);
            var directorySearch = new DirectorySearcher(parentEntry);
            var username = Console.ReadLine();

            PrincipalContext ctx = new PrincipalContext(ContextType.Domain);
            UserPrincipal user = UserPrincipal.FindByIdentity(ctx, username);
            //if (user.IsAccountLockedOut())
            var groups = user.GetGroups();

            foreach (var group in user.GetGroups())
                {
                Console.WriteLine(group);
                }

            {
                //directorySearch.Filter = "(&(objectCategory=person)(objectClass=user)(sAMAccountName=chyzhyk*)))";
                directorySearch.Filter = "sAMAccountName="+ username;
                //directorySearch.SearchScope = SearchScope.Subtree;

                
                try
                {
                    foreach (SearchResult searchEntry in directorySearch.FindAll())
                    {
                        var entry = new DirectoryEntry(searchEntry.GetDirectoryEntry().Path);

                        if (entry.Properties["cn"].Value != null)
                            Console.WriteLine(entry.Properties["cn"].Value.ToString());
                     }
                }
                catch
                {
                    // Error handling.
                }
            } Console.ReadLine();
        }
    }
}

