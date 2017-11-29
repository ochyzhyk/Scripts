using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using System.IO;
using System.DirectoryServices;
using System.DirectoryServices.AccountManagement;


class Program
{
    static void Main(string[] args)
    {
        do
        {
            try
            {
                Console.WriteLine("Введите полное имя пользователя:");
                string username = Console.ReadLine().ToString();

                ADUser ADuser = new ADUser();
                ADGroup Group = new ADGroup();
                Program Pr = new Program();
                Choose Choose = new Choose();

                string user = ADuser.UserObject(username);

                ADuser.memberof(user);

                Console.WriteLine("\n\nДля предоставления доступа выберите групу\n" +
                                     "\n\t1 - mail_rds" +
                                     "\n\t2 - sharepoint" +
                                     "\n\t3 - lucanet" +
                                     "\n\t4 - fullaccess" +
                                     "\n\t5 - regadmin" +
                                     "\n\t6 - mail_rds_GPS" +
                                     "\n\t7 - Удалить из группы\n" +
                                     "\nДля удаления из группы введите два символа, '7' и номер группы");
                Choose.Add(user);

                //Group.AddUser(groupName, user);

                Console.WriteLine();
                Console.ReadLine();
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.ToString());
            }
        }
        while (true);
    }

}

class Choose
{ 
   public void Add(string user)
   {
       ADGroup Group = new ADGroup();
       Choose Choose = new Choose();
       char count = Convert.ToChar(Console.Read());
       switch (count)
       {
           case '1':
               Group.AddUser("mail_rds", user);
               break;
           case '2':
               Group.AddUser("sharepoint", user);
               break;
           case '3':
               Group.AddUser("lucanet", user);
               break;
           case '4':
               Group.AddUser("fullaccess", user);
               break;
           case '5':
               Group.AddUser("regadmins", user);
               break;
           case '6':
               Group.AddUser("mail_rds_GPS", user);
               break;
           case '7':
               Choose.Remove(user);
               break;
           default:
               break;
       }
       //return groupName;
   }

   public void Remove(string user)
   {
       ADGroup Group = new ADGroup();
       char ct = Convert.ToChar(Console.Read());
       switch (ct)
       {
           case '1':
               Group.RemoveUser("mail_rds", user);
               break;
           case '2':
               Group.RemoveUser("sharepoint", user);
               break;
           case '3':
               Group.RemoveUser("lucanet", user);
               break;
           case '4':
               Group.RemoveUser("fullaccess", user);
               break;
           case '5':
               Group.RemoveUser("regadmins", user);
               break;
           case '6':
               Group.RemoveUser("mail_rds_GPS", user);
               break;
           default: 
               Console.WriteLine("Cancel");
               break;
       }
   }
}


class ADUser
{
    PrincipalContext ctx = new PrincipalContext(ContextType.Domain);
    public string UserObject(string username)
    {
        UserPrincipal user = UserPrincipal.FindByIdentity(ctx, username);
        string logon = user.SamAccountName;
        return logon;
    }

    public void memberof(string username)
    {
        UserPrincipal user = UserPrincipal.FindByIdentity(ctx, username);
        string[] Groups = new string [] {"mail_rds",
                                        "sharepoint",
                                        "lucanet",
                                        "fullaccess",
                                        "regadmins",
                                        "mail_rds_GPS"};
        foreach (string group in Groups)
            if(user.IsMemberOf(ctx, IdentityType.SamAccountName, group))
                Console.WriteLine("Пользователь принадлежит группе: {0}", group);
    }
}

class ADGroup
{
    PrincipalContext ctx = new PrincipalContext(ContextType.Domain);
    public void AddUser(string groupName, string user)
    {
        GroupPrincipal group = GroupPrincipal.FindByIdentity(ctx, groupName);
        group.Members.Add(ctx, IdentityType.SamAccountName, user);
        group.Save();
        Console.WriteLine("Пользователь добавлен в группу: {0}", groupName);
    
    }

    public void RemoveUser(string groupName, string user)
    {
        GroupPrincipal group = GroupPrincipal.FindByIdentity(ctx, groupName);
        group.Members.Remove(ctx, IdentityType.SamAccountName, user);
        group.Save();
        Console.WriteLine("Пользователь удален из группы: {0}", groupName);
    }
}