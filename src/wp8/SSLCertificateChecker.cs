using System.Threading.Tasks;
using System.Collections.Generic;
using System.Windows;
using System.Windows.Controls;
using Microsoft.Phone.Controls;
using System.Windows.Controls.Primitives;
using System.Windows.Media;
using Windows.Security.Cryptography.Certificates;

namespace WPCordovaClassLib.Cordova.Commands
{
    public class SSLCertificateChecker : BaseCommand
    {

        public void check(string options)
        {
//            string[] args = JSON.JsonHelper.Deserialize<string[]>(options);
//            var input = args[0];
//            DispatchCommandResult(new PluginResult(PluginResult.Status.INSTANTIATION_EXCEPTION));

             // Send a get request to Bing
            HttpClient client = new HttpClient();
            Uri bingUri = new Uri("https://www.bing.com"); // TODO from plugin interface
            HttpResponseMessage response = await client.GetAsync(bingUri);

            // Get the list of certificates that were used to validate the server's identity
            IReadOnlyList<Certificate> serverCertificates = response.RequestMessage.TransportInformation.ServerIntermediateCertificates;

            // Perform validation
            if (!ValidCertificates(serverCertificates))
            {
                // Close connection as chain is not valid
                return;
            }

//            PrintResults("Validation passed\n");
            // Validation passed, continue with connection to service
        }

        private bool ValidCertificates(IReadOnlyList<Certificate> certs)
        {
            // In this example, we iterate through the certificates and check that the chain contains
            // one specific certificate we are expecting
            for(int i=0; i<certs.Count; i++)
            {
                PrintResults("Cert# " + i + ": " + certs[i].Subject + "\n");
                byte[] thumbprint = certs[i].GetHashValue();

                // Check if the thumbprint matches whatever you are expecting
                // ‎d4 de 20 d0 5e 66 fc 53 fe 1a 50 88 2c 78 db 28 52 ca e4 74
                byte[] expected = new byte[] { 212, 222, 32, 208, 94, 102, 252, 83, 254, 26, 80, 136, 44, 120, 219, 40, 82, 202, 228, 116 };

                if (ThumbprintMatches(thumbprint, expected))
                {
                    return true;
                }
            }

            return false;
        }
    }
}
