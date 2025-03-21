with Ada.Text_IO;            use Ada.Text_IO;
with Ada.Strings.Fixed;      use Ada.Strings.Fixed;
with Ada.Strings;            use Ada.Strings;
with Ada.Exceptions;         use Ada.Exceptions;
with Ada.Assertions;         use Ada.Assertions;
with Ada.Characters.Latin_1; use Ada.Characters.Latin_1;
with Ada.Directories;        use Ada.Directories;
with Ada.Command_Line;       use Ada.Command_Line;

procedure Main is

   -- Tweak these figures until just over 1_000_000 SLOC is reported by
   --
   --    gnatmetric --lines-code -P build.gpr
   --
   type Package_Count_T is range 1 .. 10;
   type Subprogram_Count_Type is range 1 .. 1_925;  -- roughly 250k SLOC

   Main_Program_Signature : constant String := "procedure Main is";
   Main_Program_End       : constant String := "end Main;";

   procedure Write_Package_Body_Header
     (Into : in Ada.Text_IO.File_Type; Package_Index : in String) is
   begin
      Put_Line
        (File => Into, Item => "package body P_" & Package_Index & " is");
   end Write_Package_Body_Header;

   procedure Write_Package_Spec_Header
     (Into : in Ada.Text_IO.File_Type; Package_Index : in String) is
   begin
      Put_Line (File => Into, Item => "with Interfaces;");
      Put_Line (File => Into, Item => "package P_" & Package_Index & " is");
   end Write_Package_Spec_Header;

   procedure Write_Package_Footer
     (Into : in Ada.Text_IO.File_Type; Package_Index : in String) is
   begin
      Put_Line (File => Into, Item => LF & "end P_" & Package_Index & ";");
   end Write_Package_Footer;

   procedure Write_Subprograms
     (Into_Spec : in Ada.Text_IO.File_Type;
      Into_Body : in Ada.Text_IO.File_Type) is
   begin

      For_Each_Subprogram :
      for Subprogram_Index in Subprogram_Count_Type loop

         Write_Subprogram :
         declare

            Subprogram_Index_As_String : constant String :=
              Trim (Subprogram_Index'Img, Ada.Strings.Left);

            Proc_Name : constant String := "P" & Subprogram_Index_As_String;
            Func_Name : constant String := "F" & Subprogram_Index_As_String;

         begin

            Put_Line
              (File => Into_Spec,
               Item =>
                 "function "
                 & Func_Name
                 & " (I : in Interfaces.Unsigned_32) return Interfaces.Unsigned_32;");

            Put_Line
              (File => Into_Spec,
               Item =>
                 "procedure "
                 & Proc_Name
                 & " (I : in out Interfaces.Unsigned_32);");

            Put_Line
              (File => Into_Body,
               Item =>
                 LF
                 & "function "
                 & Func_Name
                 & " (I : in Interfaces.Unsigned_32) return Interfaces.Unsigned_32 is"
                 & LF
                 & "begin"
                 & LF & HT
                 & (if Subprogram_Index mod 2 = 0
                    then "return Interfaces.Unsigned_32'Succ (I);"
                    else "return Interfaces.Unsigned_32'Pred (I);")
                 & LF
                 & "end "
                 & Func_Name
                 & ";");

            Put_Line
              (File => Into_Body,
               Item =>
                 LF
                 & "procedure "
                 & Proc_Name
                 & " (I : in out Interfaces.Unsigned_32) is"
                 & LF
                 & "begin"
                 & LF & HT
                 & "I := " & Func_Name & " (I);"
                 & LF
                 & "end "
                 & Proc_Name
                 & ";");

         end Write_Subprogram;

      end loop For_Each_Subprogram;

   end Write_Subprograms;

   procedure Write_Subprogram_Calls (Into : Ada.Text_IO.File_Type) is
   begin

      For_Each_Package :
      for Package_Index in Package_Count_T loop

         For_Package :
         declare
            Package_Index_As_String : constant String :=
              "P_" & Trim (Package_Index'Img, Ada.Strings.Left);
         begin

            For_Each_Subprogram :
            for Subprogram_Index in Subprogram_Count_Type loop

               For_Subprogram :
               declare

                  Subprogram_Index_As_String : constant String :=
                    Trim (Subprogram_Index'Img, Ada.Strings.Left);

                  Proc_Name : constant String := Package_Index_As_String & ".P" & Subprogram_Index_As_String;
                  Func_Name : constant String := Package_Index_As_String & ".F" & Subprogram_Index_As_String;

               begin

                  Put_Line
                    (File => Into,
                     Item => HT & Proc_Name & " (I => An_Unsigned_32);" & LF);

                  Put_Line
                    (File => Into,
                     Item => HT & "An_Unsigned_32 := " & Func_Name & " (I => An_Unsigned_32);" & LF);

               end For_Subprogram;

            end loop For_Each_Subprogram;

         end For_Package;

      end loop For_Each_Package;

   end Write_Subprogram_Calls;

   Main_Program_File_Handle : Ada.Text_IO.File_Type;

begin

   -- The program needs 1 command line option, the name of a directory
   -- in which to generate the source code. It can already exist and all
   -- files to be generated that exist in it, will be overwritten.

   if Argument_Count /= 1 then
      Put_Line ("usage: jubilent-fortnight.exe {output directory}");
      Set_Exit_Status (Failure);
      return;
   end if;

   Output_Directory_Handling :
   declare
      Directory_Name : constant String := Argument (1);
   begin

      if Exists (Directory_Name) then
         Delete_Tree (Directory_Name);
      end if;

      Create_Directory (New_Directory => Directory_Name);

      Set_Directory (Directory_Name);

      -- Write a VSCode settings.json in a .vscode subdirectory
      Create_And_Write_VSCode_Settings_File:
      declare
         VSCode_Directory_Name : constant String := ".vscode";
         VSCode_Settings_File_Handle : Ada.Text_IO.File_Type;       
      begin
         
         Create_Directory (VSCode_Directory_Name);
         Set_Directory (VSCode_Directory_Name);         

         Create
           (File => VSCode_Settings_File_Handle,
            Mode => Out_File,
            Name => "settings.json");

         Put_Line
           (File => VSCode_Settings_File_Handle,
            Item => "{ ""ada.projectFile"": ""build.gpr""}");

         Close (File => VSCode_Settings_File_Handle);

         Set_Directory (Directory_Name);

      end Create_And_Write_VSCode_Settings_File;

   end Output_Directory_Handling;

   For_Each_Package :
   for Package_Index in Package_Count_T loop

      For_Package :
      declare

         Package_Index_As_String : constant String :=
           Trim (Package_Index'Img, Ada.Strings.Left);

         Current_Package_Spec_File_Handle : Ada.Text_IO.File_Type;
         Current_Package_Body_File_Handle : Ada.Text_IO.File_Type;

      begin

         Create
           (File => Current_Package_Spec_File_Handle,
            Mode => Out_File,
            Name => "p_" & Package_Index_As_String & ".ads");

         Create
           (File => Current_Package_Body_File_Handle,
            Mode => Out_File,
            Name => "p_" & Package_Index_As_String & ".adb");

         Write_Package_Spec_Header
           (Into          => Current_Package_Spec_File_Handle,
            Package_Index => Package_Index_As_String);

         Write_Package_Body_Header
           (Into          => Current_Package_Body_File_Handle,
            Package_Index => Package_Index_As_String);

         Write_Subprograms
           (Into_Spec => Current_Package_Spec_File_Handle,
            Into_Body => Current_Package_Body_File_Handle);

         Write_Package_Footer
           (Into          => Current_Package_Spec_File_Handle,
            Package_Index => Package_Index_As_String);

         Write_Package_Footer
           (Into          => Current_Package_Body_File_Handle,
            Package_Index => Package_Index_As_String);

         Close (File => Current_Package_Spec_File_Handle);

         Close (File => Current_Package_Body_File_Handle);

      end For_Package;

   end loop For_Each_Package;

   Produce_Source_File_List :
   declare
      Source_File_List_Handle : Ada.Text_IO.File_Type;
   begin

      Create
        (File => Source_File_List_Handle,
         Mode => Out_File,
         Name => "source_file_list");

      Put_Line (File => Source_File_List_Handle, Item => "main.adb");

      For_Each_Source_File :
      for Package_Index in Package_Count_T loop

         For_Source_File :
         declare
            Package_Index_As_String : constant String :=
              Trim (Package_Index'Img, Ada.Strings.Left);
         begin

            Put_Line
              (File => Source_File_List_Handle,
               Item => "p_" & Package_Index_As_String & ".ads");

            Put_Line
              (File => Source_File_List_Handle,
               Item => "p_" & Package_Index_As_String & ".adb");

         end For_Source_File;

      end loop For_Each_Source_File;

      Close (File => Source_File_List_Handle);

   end Produce_Source_File_List;

   Create
     (File => Main_Program_File_Handle,
      Mode => Out_File,
      Name => "main.adb");

   For_Each_Package_With_Claus :
   for Package_Index in Package_Count_T loop

      Write_With_Clause :
      declare
         Package_Index_As_String : constant String :=
           Trim (Package_Index'Img, Ada.Strings.Left);
      begin

         Put_Line
           (File => Main_Program_File_Handle,
            Item => "with p_" & Package_Index_As_String & ";");

      end Write_With_Clause;

   end loop For_Each_Package_With_Claus;

   Write_Main_Program :
   declare
   begin

      Put_Line
        (File => Main_Program_File_Handle,
         Item =>
           "with Interfaces; use Interfaces;"
           & LF & LF
           & "procedure Main is"
           & LF & HT
           & "An_Unsigned_32 : Unsigned_32 := Unsigned_32'First;"
           & LF
           & "begin"
           & LF);

      Write_Subprogram_Calls (Into => Main_Program_File_Handle);

      Put_Line (File => Main_Program_File_Handle, Item => "end Main;");

   end Write_Main_Program;

   Close (File => Main_Program_File_Handle);

   Write_GPR_File :
   declare
      use Ada.Characters.Latin_1;
      GPR_File_Handle : Ada.Text_IO.File_Type;
   begin

      Create (File => GPR_File_Handle, Mode => Out_File, Name => "build.gpr");

      Put_Line
        (File => GPR_File_Handle,
         Item =>
           "project Build is"
           & LF
           & HT
           & "for Languages use"
           & Ada.Characters.Latin_1.Space
           & Left_Parenthesis
           & Quotation
           & "Ada"
           & Quotation
           & Right_Parenthesis
           & Semicolon
           & LF
           & HT
           & "for Source_Dirs use"
           & Ada.Characters.Latin_1.Space
           & Left_Parenthesis
           & Quotation
           & "."
           & Quotation
           & Right_Parenthesis
           & Semicolon
           & LF
           & HT
           & "for Source_List_File use"
           & Ada.Characters.Latin_1.Space
           & Quotation
           & "source_file_list"
           & Quotation
           & Semicolon
           & LF
           & HT
           & "for Object_Dir use"
           & Ada.Characters.Latin_1.Space
           & Quotation
           & "obj"
           & Quotation
           & Semicolon
           & LF
           & HT
           & "for Exec_Dir use"
           & Ada.Characters.Latin_1.Space
           & Quotation
           & "."
           & Quotation
           & Semicolon
           & LF
           & HT
           & "for Main use"
           & Ada.Characters.Latin_1.Space
           & Left_Parenthesis
           & Quotation
           & "main.adb"
           & Quotation
           & Right_Parenthesis
           & Semicolon
           & LF
           & "end Build;");

      Close (File => GPR_File_Handle);

   end Write_GPR_File;

   -- Write a VSCode settings.json in a .vscode subdirectory
   Create_And_Write_VSCode_Settings_File:
   declare
   begin
      null;
   end Create_And_Write_VSCode_Settings_File;

   Set_Exit_Status (Success);

exception
   when Err : others =>
      Put_Line (Ada.Exceptions.Exception_Information (Err));
      Set_Exit_Status (Failure);
end Main;
