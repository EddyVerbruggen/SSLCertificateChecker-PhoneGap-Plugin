package nl.xservices.plugins;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

import javax.net.ssl.HttpsURLConnection;
import javax.security.cert.CertificateException;
import java.io.IOException;
import java.net.URL;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.cert.Certificate;
import java.security.cert.CertificateEncodingException;

public class SSLCertificateChecker extends CordovaPlugin {

  private static final String ACTION_CHECK_EVENT = "check";
  private static char[] HEX_CHARS = {'0', '1', '2', '3', '4', '5', '6', '7', '8', '9', 'A', 'B', 'C', 'D', 'E', 'F'};

  @Override
  public boolean execute(final String action, final JSONArray args, final CallbackContext callbackContext) throws JSONException {
    if (ACTION_CHECK_EVENT.equals(action)) {
      cordova.getThreadPool().execute(new Runnable() {
        public void run() {
          try {
            final String serverURL = args.getString(0);
            final Boolean checkInCertChain = args.getBoolean(1);
            final String allowedFingerprint = args.getString(2);
            final String allowedFingerprintAlt = args.getString(3);
            String[] serverCertFingerprints = getFingerprints(serverURL);
            
            Boolean certFound = false;
            int certChainCheckDepth = checkInCertChain ? serverCertFingerprints.length : 1;
            for (int i=0; i<certChainCheckDepth; i++) {
	            if (allowedFingerprint.equalsIgnoreCase(serverCertFingerprints[i]) || allowedFingerprintAlt.equalsIgnoreCase(serverCertFingerprints[i])) {
	            	certFound = true;
	            	callbackContext.success("CONNECTION_SECURE");
	            	break;
	            }
            }
            if (! certFound) {
            	callbackContext.error("CONNECTION_NOT_SECURE");
            }
          } catch (Exception e) {
            callbackContext.error("CONNECTION_FAILED. Details: " + e.getMessage());
          }
        }
      });
      return true;
    } else {
      callbackContext.error("sslCertificateChecker." + action + " is not a supported function. Did you mean '" + ACTION_CHECK_EVENT + "'?");
      return false;
    }
  }

  private static String[] getFingerprints(String httpsURL) throws IOException, NoSuchAlgorithmException, CertificateException, CertificateEncodingException {
    final HttpsURLConnection con = (HttpsURLConnection) new URL(httpsURL).openConnection();
    con.setConnectTimeout(5000);
    con.connect();
    final Certificate[] certs = con.getServerCertificates();
    final String[] fingerprints = new String[certs.length];
    final MessageDigest md = MessageDigest.getInstance("SHA1");
    for (int i=0; i<certs.length; i++) {
        md.update(certs[i].getEncoded());
        fingerprints[i]=dumpHex(md.digest());
    }
    return fingerprints;
  }

  private static String dumpHex(byte[] data) {
    final int n = data.length;
    final StringBuilder sb = new StringBuilder(n * 3 - 1);
    for (int i = 0; i < n; i++) {
      if (i > 0) {
        sb.append(' ');
      }
      sb.append(HEX_CHARS[(data[i] >> 4) & 0x0F]);
      sb.append(HEX_CHARS[data[i] & 0x0F]);
    }
    return sb.toString();
  }
}
