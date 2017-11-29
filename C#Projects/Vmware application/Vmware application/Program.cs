using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;
using VMware.Vim;
using System.Collections.Specialized;
using VMware.VimAutomation.Sdk.Util10Ps;

namespace Vmware_application
{
    class Program
    {
        static void Main(string[] args)
        {
            List<EntityViewBase> vmlist = new List<EntityViewBase>();
            List<EntityViewBase> hostlist = new List<EntityViewBase>();
            List<EntityViewBase> clusterlist = new List<EntityViewBase>();
            List<EntityViewBase> datastorelist = new List<EntityViewBase>();
            //List<HostStorageSystem> hsObjects = new List<HostStorageSystem>();
            List<VirtualMachine> vmObjects = new List<VirtualMachine>();
            List<EntityViewBase> hssystem = new List<EntityViewBase>();

            VimClient Client = new VimClientImpl();
            string dsref = "Datastore-datastore-153";

            //ManagedObjectReference moref = new ManagedObjectReference(dsref);

            Client.Connect("https://vcenter.dc.local/sdk");
            Client.Login("user", "pass");


            NameValueCollection filter = new NameValueCollection();
            filter.Add("name", "esxhost");

            hostlist = Client.FindEntityViews(typeof(HostSystem), null, filter, null);
            datastorelist = Client.FindEntityViews(typeof(Datastore), null, null, null);
            foreach (HostSystem host in hostlist)
            {
                Console.WriteLine(host.MoRef);
                ManagedObjectReference moref = new ManagedObjectReference((host.MoRef).ToString());
                HostStorageSystem hss = new HostStorageSystem(Client, moref);
                Console.WriteLine(hss.FileSystemVolumeInfo);
            }

            foreach (Datastore DS in datastorelist)
                Console.WriteLine(DS.Name);
            
            //HostStorageSystem hss = new HostStorageSystem(Client, moref);
            //hssystem = Client.FindEntityViews(typeof(HostStorageSystem), null, null, null);
            //foreach (HostStorageSystem hs in hss)
                    
                //Console.WriteLine(vmObjects.FindLast(vm));
            //}
            
            //Console.WriteLine(hsObjects.FindAll());

            Console.ReadLine();
        }
    }
}
