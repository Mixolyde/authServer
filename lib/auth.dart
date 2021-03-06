part of authServer;

@app.Group('/auth')
class AuthService
{
	@app.Route('/login', methods: const[app.POST])
    Future<Map> loginUser(@app.Body(app.JSON) Map parameters)
    {
		Random rand = new Random();
    	Completer c = new Completer();

    	//TODO: this must be changed to not allow the client to dictate what the audience is
    	//according to the persona docs. However, for testing purposes,
    	//this is a necessary evil.
    	String audience = 'http://play.childrenofur.com:80';
    	if(parameters['testing'] != null)
    		audience = 'http://localhost:8080';
    	if(parameters['audience'] != null)
    		audience = parameters['audience'];

    	Map body = {'assertion':parameters['assertion'],
    				'audience':audience};

    	//TODO find a way to mock this call for testing
    	http.post('https://verifier.login.persona.org/verify',body:body).then((response)
		{
			Map responseMap = JSON.decode(response.body);
			print('responseMap: $responseMap');
			if(responseMap['status'] == 'okay')
			{
				createSession(responseMap['email']).then((String sessionKey)
				{
				  //TODO remove default player street
					c.complete({'ok':'yes',
    							'slack-team':slackTeam,
    							'slack-token':bugToken,
    							'sc-token':scToken,
    							'sessionToken':sessionKey,
    							'playerName':SESSIONS[sessionKey].username,
    							'playerStreet':'LA58KK7B9O522PC'});
				});
			}
			else
				c.complete({'ok':'no'});
		});

    	return c.future;
    }

	@app.Route('/logout', methods: const[app.POST])
    Map logoutUser(@app.Body(app.JSON) Map parameters)
    {
		//should remove any session key associated with parameters['sessionToken']
		SESSIONS.remove([parameters['sessionToken']]);
		return {'ok':'yes'};
    }

	//creates an entry in the SESSIONS map and returns the username associated with the session
	Future<String> createSession(String email)
	{
		Completer c = new Completer();
		http.post('http://childrenofur.com/getUsername.php',body:{'email':email}).then((response)
		{
			String username = response.body;
			String sessionKey = uuid.v1();
			Session session = new Session(sessionKey, username, email);

			SESSIONS[sessionKey] = session;
			c.complete(sessionKey);
		});

		return c.future;
	}
}