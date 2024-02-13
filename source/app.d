import std.stdio;
import std.string;
import std.file;
import std.conv;

import bindbc.loader;
import bindbc.sdl;
import bindbc.opengl;

import core.thread.osthread;
import core.time;

struct ShaderResult {
	GLuint programId;
	GLuint gIBO;
	GLuint gVBO;
	GLint gVertexPos2DLocation;
	GLint iTime;
	GLint iResolution;
	bool status;
}

int makeVertexShader(GLuint gProgramID, string shaderSource) {
	GLuint vertexShader = glCreateShader(GL_VERTEX_SHADER);
	const GLchar* vertexShaderSource = shaderSource.toStringz();

	glShaderSource(vertexShader, 1, &vertexShaderSource, null);

	glCompileShader(vertexShader);

	// Check vertex shader for errors
    GLint vShaderCompiled = GL_FALSE;
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &vShaderCompiled);

    if (vShaderCompiled != GL_TRUE) {
        printf( "Unable to compile vertex shader %d!\n", vertexShader );
		return -1;
    }
	
	//Attach vertex shader to program
	glAttachShader(gProgramID, vertexShader);
	return 0;
}

int makeFragmentShader(GLuint gProgramID, string shaderSource) {
	GLuint vertexShader = glCreateShader(GL_FRAGMENT_SHADER);
	const GLchar* vertexShaderSource = shaderSource.toStringz();

	glShaderSource(vertexShader, 1, &vertexShaderSource, null);

	glCompileShader(vertexShader);

	// Check vertex shader for errors
    GLint vShaderCompiled = GL_FALSE;
    glGetShaderiv(vertexShader, GL_COMPILE_STATUS, &vShaderCompiled);

    if (vShaderCompiled != GL_TRUE) {
        printf( "Unable to compile vertex shader %d!\n", vertexShader );
		return -1;
    }
	
	//Attach vertex shader to program
	glAttachShader(gProgramID, vertexShader);
	return 0;
}

ShaderResult makeShader(string vertextShaderSrc, string framentShaderSrc) {
	ShaderResult res;

	res.programId = glCreateProgram();
	res.gVBO = 0;
	res.gIBO = 0;
	res.gVertexPos2DLocation = 0;
	res.iTime = -1;
	res.iResolution = -1;
	res.status = false;

	string shaderSource = readText(vertextShaderSrc);
	if (makeVertexShader(res.programId, shaderSource) != 0) {
		return res;
	}

	shaderSource = readText(framentShaderSrc);
	// printf("file content: %s", fragmentShaderSource.toStringz());
	if (makeFragmentShader(res.programId, shaderSource) != 0) {
		return res;
	}

	//Link program
	glLinkProgram(res.programId);

	// Check for errors
	GLint programSuccess = GL_TRUE;
	glGetProgramiv(res.programId, GL_LINK_STATUS, &programSuccess);
	if (programSuccess != GL_TRUE) {
		printf("Error linking program %d!\n", res.programId);
		return res;
	}

	// Get vertex attribute location
	res.gVertexPos2DLocation = glGetAttribLocation(res.programId, "LVertexPos2D");
	if (res.gVertexPos2DLocation == -1) {
		printf("LVertexPos2D is not a valid glsl program variable!\n");
		return res;
	}

	res.iResolution = glGetUniformLocation(res.programId, "iResolution");
	if (res.iResolution == -1) {
		printf("iResolution is not a valid glsl program variable!\n");
		return res;
	}

	res.iTime = glGetUniformLocation(res.programId, "iTime");
	if (res.iTime == -1) {
		printf("iTime is not a valid glsl program variable!\n");
		return res;
	}

	//Initialize clear color
	glClearColor( 0.0, 0.0, 0.0, 1.0 );

	//VBO data
	GLfloat[] vertexData =
	[
		-1.0f, -1.0f,
		1.0f, -1.0f,
		1.0f,  1.0f,
		-1.0f,  1.0f
	];

	// IBO data
	GLuint[] indexData = [ 0, 1, 2, 3 ];

	// Create VBO
	glGenBuffers(1, &res.gVBO);
	glBindBuffer(GL_ARRAY_BUFFER, res.gVBO);
	glBufferData(GL_ARRAY_BUFFER, 2 * 4 * GLfloat.sizeof, cast(void*)vertexData, GL_STATIC_DRAW);

	// Create IBO
	glGenBuffers(1, &res.gIBO);
	glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, res.gIBO);
	glBufferData(GL_ELEMENT_ARRAY_BUFFER, 4 * GLuint.sizeof, cast(void*)indexData, GL_STATIC_DRAW);

	res.status = true;

	return res;
}

void render(ShaderResult shaderResult, int iTime, int width, int height) {
	glClear(GL_COLOR_BUFFER_BIT);

	//Bind program
	glUseProgram(shaderResult.programId);

	//Enable vertex position
	glEnableVertexAttribArray(shaderResult.gVertexPos2DLocation);

	// pass parameter inside shader
	glUniform1i(shaderResult.iTime, iTime);

	GLfloat[] iResolution = [width, height];
	glUniform2fv(shaderResult.iResolution, 1, iResolution.ptr);

	//Set vertex data
	glBindBuffer(GL_ARRAY_BUFFER, shaderResult.gVBO);
	glVertexAttribPointer(shaderResult.gVertexPos2DLocation, 2, GL_FLOAT, GL_FALSE, 2 * GLfloat.sizeof, null);

	//Set index data and render
	glBindBuffer( GL_ELEMENT_ARRAY_BUFFER, shaderResult.gIBO);
	glDrawElements( GL_TRIANGLE_FAN, 4, GL_UNSIGNED_INT, null);

	//Disable vertex position
	glDisableVertexAttribArray(shaderResult.gVertexPos2DLocation);

	// Unbind program
	glUseProgram(0);
}

void main() {
	if(loadSDL() != sdlSupport){
		writeln("SDL doesn't support");
	}

	SDL_Init(SDL_INIT_VIDEO);

	int width = 800;
	int height = 600;

	// Create a window
	SDL_Window* appWin = SDL_CreateWindow(
		"SDL OpenGL Shadertoy",
		SDL_WINDOWPOS_UNDEFINED,
		SDL_WINDOWPOS_UNDEFINED,
		width,
		height,
		SDL_WINDOW_OPENGL | SDL_WINDOW_SHOWN
	);

	if (appWin is null) {
		writefln("SDL_CreateWindow: ", SDL_GetError());
		return;
	}

	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MAJOR_VERSION, 3);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_MINOR_VERSION, 1);
	SDL_GL_SetAttribute(SDL_GL_CONTEXT_PROFILE_MASK, SDL_GL_CONTEXT_PROFILE_CORE);

	// Set OpenGL attributes
    SDL_GL_SetAttribute(SDL_GL_DOUBLEBUFFER, 1);
    SDL_GL_SetAttribute(SDL_GL_DEPTH_SIZE, 24);

	SDL_GLContext glcontext = SDL_GL_CreateContext(appWin);

	GLSupport retVal = loadOpenGL();
	if (retVal != GLSupport.gl41) {
		printf("Can't load openGL");
	}

	ShaderResult shaderResult = makeShader(
		"./source/shaders/shader.vert",
		"./source/shaders/shader.frag"
	);
	
	// Polling for events
	SDL_Event event;
	bool quit = false;

	int iTime = 0;

	while(!quit) {
		while (SDL_PollEvent(&event)) {
			if (event.type == SDL_QUIT) {
				quit = true;
			}
		}

		render(shaderResult, iTime++, width, height);
		SDL_GL_SwapWindow(appWin);
		Thread.sleep(dur!("msecs")(1));
	}

	// Close and destroy the window
	if (appWin !is null) {
		SDL_DestroyWindow(appWin);
	}

	glDeleteProgram(shaderResult.programId);
	SDL_GL_DeleteContext(glcontext);
	SDL_Quit();
}
