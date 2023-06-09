#include <iostream>      //input and output streams
#include <GL/glut.h>     // glut files
#include <GL/freeglut.h> // glut files
#include <time.h>
#include <stdlib.h>
#include <unistd.h>
#include <cuda_runtime.h>
#include <cuda.h>

using namespace std;

#define win_width 840  // 840
#define win_height 480 // 480s

#define starting_state 0
#define game_choose_state 1
#define propagating_state 2
#define last_state 3

int GameState;
int i, j;
int neighbourCount;

bool *GameMatrix;
bool *TempMatrix;

bool has_life;
int count = 0;

/***************************************************************************/

void header()
{

    const unsigned char name[40] = "GAME OF LIFE";

    glClear(GL_COLOR_BUFFER_BIT);
    glColor3f(0.34, 0.24, 1);

    glRasterPos2f(377, 450);
    glColor4f(0.0f, 0.0f, 1.0f, 1.0f);
    glutBitmapString(GLUT_BITMAP_HELVETICA_18, name);

    glutSwapBuffers();
}

void print_grid()
{

    glColor3f(0.0f, 0.4f, 0.0f);
    glBegin(GL_LINES);

    for (i = 20; i <= 820; i += 20)
    {

        glVertex2f(i, 440);
        glVertex2f(i, 40);
    }

    for (i = 40; i <= 440; i += 20)
    {

        glVertex2f(20, i);
        glVertex2f(820, i);
    }

    glEnd();

    glutSwapBuffers();
}

void update_display()
{

    header();

    glColor3f(0.0f, 0.4f, 0.0f);
    for (i = 0; i < 40; i++)
        for (j = 0; j < 20; j++)
        {

            if (*(GameMatrix + i * 20 + j) == true)
            {

                glBegin(GL_POLYGON);

                glVertex2f(i * 20 + 19, j * 20 + 39);
                glVertex2f(i * 20 + 39, j * 20 + 39);
                glVertex2f(i * 20 + 39, j * 20 + 59);
                glVertex2f(i * 20 + 19, j * 20 + 59);

                glEnd();
            }
        }

    glutSwapBuffers();
}

void LastRight()
{

    cout << "@ last rights" << endl;

    header();

    GameState = last_state;

    glColor3f(0.4, 0, 0);

    const unsigned char msg[40] = "YOU DIDN'T SURVIVE THE LIFE";
    const unsigned char restart[40] = " RESTART ";
    const unsigned char quit[40] = "QUIT";

    glClear(GL_COLOR_BUFFER_BIT);

    glRasterPos2f(265, 367);
    glutBitmapString(GLUT_BITMAP_HELVETICA_18, msg);

    glutSwapBuffers();

    glColor3f(0.26, 0.17, 0.36); // start button
    glBegin(GL_POLYGON);

    glVertex2f(230, 300);
    glVertex2f(350, 300);
    glVertex2f(350, 230);
    glVertex2f(230, 230);

    glEnd();

    glBegin(GL_POLYGON); // end button

    glVertex2f(480, 300);
    glVertex2f(600, 300);
    glVertex2f(600, 230);
    glVertex2f(480, 230);

    glEnd();

    glColor3f(0.0f, 0.0f, 0.0f);
    glRasterPos2f(230, 260);
    glutBitmapString(GLUT_BITMAP_TIMES_ROMAN_24, restart);

    glRasterPos2f(500, 260);
    glutBitmapString(GLUT_BITMAP_TIMES_ROMAN_24, quit);

    glutSwapBuffers();

    glutSwapBuffers();
}

__global__ void propagate(bool *TempMatrix, bool *GameMatrix, int rows, int cols)
{

    int i = threadIdx.x;
    int j = threadIdx.y;

    int neighbourCount = 0;

    if (i > 0)
        neighbourCount += *(TempMatrix + (i - 1) * cols + j);
    if (i < 39)
        neighbourCount += *(TempMatrix + (i + 1) * cols + j);
    if (j > 0)
        neighbourCount += *(TempMatrix + i * cols + (j - 1));
    if (j < 19)
        neighbourCount += *(TempMatrix + i * cols + (j + 1));

    if (i > 0 && j > 0)
        neighbourCount += *(TempMatrix + (i - 1) * cols + (j - 1));
    if (i > 0 && j < 19)
        neighbourCount += *(TempMatrix + (i - 1) * cols + (j + 1));
    if (i < 39 && j > 0)
        neighbourCount += *(TempMatrix + (i + 1) * cols + (j - 1));
    if (i < 39 && j < 19)
        neighbourCount += *(TempMatrix + (i + 1) * cols + (j + 1));

    if (*(TempMatrix + i * cols + j) == true && neighbourCount == 2)
        *(GameMatrix + i * cols + j) = true;
    if (neighbourCount == 3)
        *(GameMatrix + i * cols + j) = true;
}

void choose()
{

    GameState = game_choose_state;

    header();

    glColor3f(0.11, 0.89, 0.34);

    print_grid();
}

void start_menu()
{

    GameState = starting_state;

    cout << "start_menu() " << GameState << endl;

    const unsigned char start[20] = "START";
    const unsigned char quit[20] = "QUIT";

    header();

    glColor3f(0.78, 0.16, 0.83);
    glBegin(GL_LINES);
    glVertex2f(0, 430);
    glVertex2f(860, 430);
    glEnd();

    glColor3f(0.16, 0.17, 0.46);
    glBegin(GL_POLYGON);

    glVertex2f(60, 300);
    glVertex2f(180, 300);
    glVertex2f(180, 230);
    glVertex2f(60, 230);

    glEnd();

    glBegin(GL_POLYGON);

    glVertex2f(660, 300);
    glVertex2f(780, 300);
    glVertex2f(780, 230);
    glVertex2f(660, 230);

    glEnd();

    glColor3f(0.0f, 1.0f, 0.0f);
    glRasterPos2f(80, 260);
    glutBitmapString(GLUT_BITMAP_TIMES_ROMAN_24, start);

    glColor3f(0.0f, 0.0f, 0.0f);
    glRasterPos2f(680, 260);
    glutBitmapString(GLUT_BITMAP_TIMES_ROMAN_24, quit);

    glutSwapBuffers();
}

void keyboard(unsigned char key, int x, int y)
{

    if (key == 'q')
        cout << "state :: " << GameState << endl;

    if (key == 27)
        exit(0);

    cout << "@ keyboard " << (int)key << endl;

    if (GameState == propagating_state)
    {

        if (key == 13)
            while (1)
            {
                sleep(2);
            }
    }
}

void mouse(int button, int state, int x, int y)
{

    if (button != GLUT_LEFT_BUTTON || state != GLUT_DOWN)
        return;

    cout << "@ mouse " << x << " " << y << " " << GameState << endl;

    switch (GameState)
    {

    case starting_state:
    {
        if (y < 180 || y > 250)
            return;

        if (x < 180 && x > 60)
            choose();

        else if (x > 660 && x < 780)
            exit(0);
    }
    break;

    case game_choose_state:
    {

        if (x < 505 && x > 380 && y <= 30 && y >= 15)
        {

            bool *dev_TempMatrix;
            bool *dev_GameMatrix;
            cudaMalloc((void **)&dev_TempMatrix, 40 * 20 * sizeof(bool));
            cudaMalloc((void **)&dev_GameMatrix, 40 * 20 * sizeof(bool));
            dim3 threadsPerBlock(40, 20);
            while (1)
            {
                clock_t start, end;
                double time_used;

                start = clock();

                for (i = 0; i < 40; i++)
                    for (j = 0; j < 20; j++)
                    {
                        *(TempMatrix + i * 20 + j) = *(GameMatrix + i * 20 + j);

                        *(GameMatrix + i * 20 + j) = false;
                    }
                cudaMemcpy(dev_GameMatrix, GameMatrix, 40 * 20 * sizeof(bool), cudaMemcpyHostToDevice);
                cudaMemcpy(dev_TempMatrix, TempMatrix, 40 * 20 * sizeof(bool), cudaMemcpyHostToDevice);
                propagate<<<1, threadsPerBlock>>>(dev_TempMatrix, dev_GameMatrix, 40, 20);
                cudaDeviceSynchronize();
                cudaMemcpy(GameMatrix, dev_GameMatrix, 40 * 20 * sizeof(bool), cudaMemcpyDeviceToHost);
                end = clock();
                time_used = ((double)(end - start)) / CLOCKS_PER_SEC;
                cout << "time used " << time_used << endl;
                update_display();
                sleep(2);
            }
            return;
        }

        if (y < 40 || y > 440 || x > 820 || x < 20)
            return;
        i = (x - 20) / 20;
        j = (480 - y - 40) / 20;

        cout << " choice " << i << " " << j << endl;

        glBegin(GL_POLYGON);

        glVertex2f(i * 20 + 20, j * 20 + 40);
        glVertex2f(i * 20 + 40, j * 20 + 40);
        glVertex2f(i * 20 + 40, j * 20 + 60);
        glVertex2f(i * 20 + 20, j * 20 + 60);

        glEnd();

        *(GameMatrix + i * 20 + j) = true;

        glutSwapBuffers();
    }
    break;

    case last_state:
    {

        if (y < 180 || y > 250)
            return;

        if (x > 230 && x < 350)
            start_menu();

        if (x < 600 && x > 480)
            exit(0);
    }
    break;
    }
}

void win_init()
{

    glClearColor(0, 0, 0, 0);
    glClear(GL_COLOR_BUFFER_BIT);
    gluOrtho2D(0, 840, 0, 480);
}

void game(int argc, char **argv)
{

    cout << "@game" << endl;

    glutInit(&argc, argv);
    glutInitWindowSize(win_width, win_height);
    glutInitWindowPosition(400, 400);
    glutInitDisplayMode(GLUT_DOUBLE | GLUT_RGB);

    glutCreateWindow("Game_of_life using Cuda");

    win_init();
    glutKeyboardFunc(keyboard);
    glutMouseFunc(mouse);

    start_menu();
    glutMainLoop();
}

int main(int argc, char **argv)
{

    cout << "@main" << endl;
    GameMatrix = (bool *)malloc(40 * 20 * sizeof(bool));
    TempMatrix = (bool *)malloc(40 * 20 * sizeof(bool));

    game(argc, argv);

    return 0;
}
