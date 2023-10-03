# 2DTopDownCharacterController
A basic character controller class for a CharacterBody2D used as a starting point for a 2d top down style game.

Implements wasd + controller movement, friction, walking, sprinting, and dashing.

https://github.com/paul-mcnamee/2DTopDownCharacterController/assets/35277807/8c6297a0-92c9-424c-a927-331d49bc970c


If you don't provide an input direction then the speed could be higher than the expected max
what this means is basically if you dash, you can go a greater distance if you let go of the direction
I think it is kind of cool because it makes it a little bit more skill based
you can for example:
	w + dash
	release w
	wait until you reach sprint speed
	hold sprint + w

depending on the friction and dash timer duration, this could make you travel a greater distance than if you would just hold w + sprint + dash

Here is a video of the above described behavior:

https://github.com/paul-mcnamee/2DTopDownCharacterController/assets/35277807/5ef649d1-17ed-40cd-924f-726b8ff7afd1



https://github.com/paul-mcnamee/2DTopDownCharacterController/assets/35277807/53874d9c-1073-427f-a9da-c1925094e400




This was adapted from dragon1freak's [PlatformCharacterController](https://github.com/dragon1freak/PlatformerCharacterController) though a lot of the behavior has changed to accommodate the top down style.

